import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../../core/utils/input_validator.dart';
import 'backup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _decoyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    _newPasswordController.dispose();
    _decoyController.dispose();
    super.dispose();
  }

  // Dialog to change Master Password
  void _showChangePasswordDialog() {
    _passwordController.clear();
    _newPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Master Password'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: (val) => InputValidator.shortPassword(val),
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                validator: (val) => InputValidator.newPassword(val, currentPassword: _passwordController.text),
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  helperText: 'Min 8 chars, 1 uppercase, 1 digit',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.changeMasterPassword(
                _passwordController.text.trim(),
                _newPasswordController.text.trim(),
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Master Password changed successfully!' : 'Incorrect current password')),
                );
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  // Dialog to change Decoy Password
  void _showDecoyPasswordDialog() {
    _decoyController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Decoy Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entering this password at login will open a dummy diary profile with sample logs, hiding your real thoughts.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _decoyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Decoy Password',
                hintText: 'e.g. Demo@123',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newDecoy = _decoyController.text.trim();
              final validationError = InputValidator.shortPassword(newDecoy);
              if (validationError != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(validationError)),
                );
                return;
              }

              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.changeDecoyPassword(newDecoy);

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Decoy password updated successfully!')),
                );
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  // Dialog to prompt password before toggling biometrics
  void _toggleBiometricEnrollment(bool enable) {
    if (!enable) {
      // Disabling biometrics: no password needed — just delete stored plain key
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setBiometricsEnabled(false, '').then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometric authentication disabled.')),
          );
        }
      }).catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to disable biometrics: $e')),
          );
        }
      });
      return;
    }

    _passwordController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Master Password'),
        content: TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              try {
                await authProvider.setBiometricsEnabled(true, _passwordController.text.trim());
                if (mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to enable biometrics. Check password.')),
                );
              }
            },
            child: const Text('VERIFY'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Security Section
          _buildSectionHeader('Security Settings'),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Master Password'),
            subtitle: const Text('Modify the password used to encrypt database'),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.lock_open),
            title: const Text('Decoy Password Settings'),
            subtitle: const Text('Configure fake/dummy login trigger'),
            onTap: _showDecoyPasswordDialog,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Unlock database with registered fingerprint'),
            value: authProvider.isBiometricEnabled,
            onChanged: _toggleBiometricEnrollment,
          ),
          
          // Auto-Lock settings
          _buildSectionHeader('Session Timeout (Auto Lock)'),
          _buildAutoLockDurationTile(const Duration(seconds: 30), '30 Seconds', authProvider),
          _buildAutoLockDurationTile(const Duration(minutes: 1), '1 Minute', authProvider),
          _buildAutoLockDurationTile(const Duration(minutes: 5), '5 Minutes', authProvider),

          // Theme preferences
          _buildSectionHeader('Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Premium Dark Theme'),
            subtitle: const Text('Toggle between dark and light appearance'),
            value: themeProvider.isDarkMode,
            onChanged: (val) => themeProvider.toggleTheme(val),
          ),

          // Backup navigation
          _buildSectionHeader('Data Management'),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Export/import encrypted databases or cloud sync'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupScreen()),
              );
            },
          ),

          // About App details
          _buildSectionHeader('About App'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('YNote Mobile Client'),
            subtitle: Text('Version 1.0.0+2 (Production Build)\nYour Thoughts. Your Memories. Your Privacy. 🔐'),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoLockDurationTile(Duration duration, String label, AuthProvider authProvider) {
    final isSelected = authProvider.autoLockDuration == duration;
    return RadioListTile<Duration>(
      title: Text(label),
      value: duration,
      groupValue: authProvider.autoLockDuration,
      onChanged: (val) {
        if (val != null) {
          authProvider.updateAutoLockDuration(val);
        }
      },
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}
