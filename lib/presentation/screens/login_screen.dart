import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/diary_provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/input_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final _recoveryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometrics if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricLogin();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _recoveryController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isBiometricEnabled) {
      final success = await authProvider.authenticateBiometrics();
      if (success && mounted) {
        _onLoginSuccess();
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final password = _passwordController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.authenticate(password);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _onLoginSuccess();
      } else {
        setState(() {
          _errorMessage = "Incorrect Password. Please try again.";
        });
      }
    }
  }

  void _onLoginSuccess() {
    // Load entries immediately into memory
    Provider.of<DiaryProvider>(context, listen: false).loadEntries();
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 1,
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lock Emblem
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.darkPrimary.withAlpha(25),
                        ),
                        child: const Icon(
                          Icons.lock_person_outlined,
                          size: 60,
                          color: AppColors.darkPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unlock YNote',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your Master Password to access your thoughts.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withAlpha(51)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Password is required';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Master Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onFieldSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 24),

                      // Actions
                      Row(
                        children: [
                          if (authProvider.isBiometricEnabled) ...[
                            IconButton(
                              onPressed: _checkBiometricLogin,
                              icon: const Icon(Icons.fingerprint, size: 36, color: AppColors.darkPrimary),
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('UNLOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          _recoveryController.clear();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.vpn_key, color: AppColors.darkPrimary),
                                  SizedBox(width: 8),
                                  Text('Password Recovery'),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Enter the 14-character Recovery Key shown during onboarding (e.g. YN-XXXX-XXXX-XXXX) to retrieve your Master Password.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _recoveryController,
                                    decoration: InputDecoration(
                                      hintText: 'Recovery Key',
                                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                                      helperText: 'Format: YN-XXXX-XXXX-XXXX',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                                    final recoveryKey = _recoveryController.text.trim();
                                    final validationError = InputValidator.recoveryKey(recoveryKey);
                                    if (validationError != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(validationError)),
                                      );
                                      return;
                                    }
                                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                    
                                    final decryptedPassword = await authProvider.recoverPassword(recoveryKey);
                                    
                                    if (mounted) {
                                      Navigator.pop(context);
                                      if (decryptedPassword != null) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Access Recovered'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Your Master Password has been decrypted successfully:'),
                                                const SizedBox(height: 12),
                                                Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.darkSecondary.withAlpha(25),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: AppColors.darkSecondary.withAlpha(51)),
                                                  ),
                                                  child: SelectableText(
                                                    decryptedPassword,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: AppColors.darkSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  _passwordController.text = decryptedPassword;
                                                  Navigator.pop(context);
                                                  _login();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.darkPrimary,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('LOGIN NOW'),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Invalid Recovery Key. Please double check and try again.')),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.darkPrimary,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('VERIFY KEY'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Forgot password?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
