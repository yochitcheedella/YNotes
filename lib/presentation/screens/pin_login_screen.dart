import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../../auth/auth_provider.dart';
import '../../core/constants/app_theme.dart';
import '../../core/utils/app_logger.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> with SingleTickerProviderStateMixin {
  String _enteredPin = "";
  String _errorMessage = "";
  int _attemptsLeft = 5;

  final LocalAuthentication _localAuth = LocalAuthentication();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Automatically trigger biometrics if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricAuthIfEnabled();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _triggerBiometricAuthIfEnabled() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isBiometricEnabled) {
      await _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isSupported) return;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock Diaro',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate && mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.unlock();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      }
    } catch (e) {
      AppLogger.error("Biometrics authentication failed", exception: e);
    }
  }

  void _onKeyPress(String val) {
    setState(() {
      _errorMessage = "";
      if (val == "back") {
        if (_enteredPin.isNotEmpty) {
          _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        }
      } else {
        if (_enteredPin.length < 6) {
          _enteredPin += val;
          if (_enteredPin.length == 6) {
            // Delay slightly for visual effect before verification
            Future.delayed(const Duration(milliseconds: 150), _verifyEnteredPin);
          }
        }
      }
    });
  }

  void _verifyEnteredPin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isValid = await authProvider.verifyPin(_enteredPin);

    if (isValid && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      _shakeController.forward(from: 0.0);
      setState(() {
        _attemptsLeft--;
        if (_attemptsLeft <= 0) {
          _errorMessage = "Too many failed attempts. Reset PIN or retry later.";
          // Optionally, disable dialpad or lock app for a duration.
        } else {
          _errorMessage = "Incorrect PIN. $_attemptsLeft attempts remaining.";
        }
        _enteredPin = "";
      });
    }
  }

  void _handleForgotPin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Security PIN?'),
        content: const Text(
          'Resetting your PIN will erase local security data and force you to configure a new PIN. Your diary entries and account session will remain safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.resetPin();
              if (mounted) {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/pin-setup');
              }
            },
            child: const Text('RESET PIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final active = index < _enteredPin.length;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.darkPrimary : Colors.transparent,
        border: Border.all(
          color: active ? AppColors.darkPrimary : Colors.white24,
          width: 2,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.darkPrimary.withAlpha(128),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
    );
  }

  Widget _buildDialButton(String text) {
    return InkWell(
      onTap: () => _onKeyPress(text),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withAlpha(10),
          border: Border.all(
            color: AppColors.darkPrimary.withAlpha(40),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildDialpad(bool isBioEnabled) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDialButton("1"),
            _buildDialButton("2"),
            _buildDialButton("3"),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDialButton("4"),
            _buildDialButton("5"),
            _buildDialButton("6"),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDialButton("7"),
            _buildDialButton("8"),
            _buildDialButton("9"),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Biometrics button
            if (isBioEnabled)
              InkWell(
                onTap: _authenticateWithBiometrics,
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.darkPrimary.withAlpha(30),
                    border: Border.all(
                      color: AppColors.darkPrimary.withAlpha(80),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.fingerprint,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              )
            else
              const SizedBox(width: 75),
            _buildDialButton("0"),
            InkWell(
              onTap: () => _onKeyPress("back"),
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 75,
                height: 75,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.backspace_outlined,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF140F0A),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // App Brand
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.security,
                    color: AppColors.darkPrimary,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DIARO',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'ENCRYPTION ACTIVE: PBKDF2-HMAC-SHA256',
                style: TextStyle(
                  color: AppColors.darkPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              // Title / Action Message
              const Text(
                'Secure Entry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter PIN to unlock your secure logs',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              // Indicators
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value * (1 - (_shakeController.value * 2)), 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) => _buildDot(index)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Error text
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              const Spacer(flex: 2),
              // Dialpad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: _buildDialpad(authProvider.isBiometricEnabled),
              ),
              const Spacer(),
              // Forgot PIN Button
              TextButton(
                onPressed: _handleForgotPin,
                child: const Text(
                  'Forgot PIN?',
                  style: TextStyle(
                    color: AppColors.darkPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
