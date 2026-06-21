import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/input_validator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _obscurePassword = true;
  bool _enableBiometrics = false;
  bool _isSubmitting = false;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Welcome to Diaro',
      'description': 'Your ultimate personal diary and journal designed to capture your memories while keeping them entirely private.',
      'icon': '📝',
    },
    {
      'title': 'Military-Grade Security',
      'description': 'Your entries are encrypted locally on your device using AES-256 encryption. Only you hold the key to decrypt them.',
      'icon': '🔐',
    },
    {
      'title': 'Complete Privacy Control',
      'description': 'Protect your thoughts with fingerprint verification and double-agent Decoy password triggers to hide real logs.',
      'icon': '👤',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitMasterPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Save password and complete onboarding (returns recovery key)
      final recoveryKey = await authProvider.setupMasterPassword(_passwordController.text.trim());
      
      if (_enableBiometrics) {
        try {
          await authProvider.setBiometricsEnabled(true, _passwordController.text.trim());
        } catch (e) {
          // Biometric setup might fail on emulators without fingerprint hardware
          AppLogger.warning("Biometrics not setup on device: $e");
        }
      }

      if (mounted) {
        // Force the user to review and save the recovery key
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.vpn_key, color: AppColors.darkPrimary),
                SizedBox(width: 8),
                Text('Save Recovery Key'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Write down this key. If you forget your password, this is the ONLY way to recover your encrypted journal logs.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.darkPrimary.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.darkPrimary.withAlpha(51)),
                  ),
                  child: Center(
                    child: SelectableText(
                      recoveryKey,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.0,
                        color: AppColors.darkPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Tap and hold key to copy to clipboard',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('I HAVE WRITTEN IT DOWN'),
              ),
            ],
          ),
        );

        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete onboarding: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemCount: _slides.length + 1, // +1 for the Password setup page
                  itemBuilder: (context, index) {
                    if (index < _slides.length) {
                      final slide = _slides[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            slide['icon']!,
                            style: const TextStyle(fontSize: 80),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            slide['title']!,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide['description']!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    } else {
                      // Password setup page
                      return SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              const Text('🔑', style: TextStyle(fontSize: 60)),
                              const SizedBox(height: 16),
                              Text(
                                'Setup Master Password',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a password to encrypt and secure your diary. This password cannot be recovered if forgotten.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 32),
                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: InputValidator.masterPassword,
                                decoration: InputDecoration(
                                  labelText: 'Master Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Confirm password field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscurePassword,
                                validator: (val) {
                                  if (val != _passwordController.text) return 'Passwords do not match';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Biometrics switch
                              SwitchListTile(
                                title: const Text('Enable Fingerprint Login'),
                                subtitle: const Text('Unlock Diaro using biometric authentication'),
                                value: _enableBiometrics,
                                onChanged: (val) => setState(() => _enableBiometrics = val),
                                activeColor: AppColors.darkPrimary,
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              // Pagination indicator dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length + 1,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index 
                          ? AppColors.darkPrimary 
                          : (isDark ? Colors.white30 : Colors.black26),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Back/Next Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _currentPage > 0
                      ? TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('BACK'),
                        )
                      : const SizedBox(width: 80),
                  ElevatedButton(
                    onPressed: _currentPage == _slides.length
                        ? (_isSubmitting ? null : _submitMasterPassword)
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_currentPage == _slides.length ? 'GET STARTED' : 'NEXT'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
