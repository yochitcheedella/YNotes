import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/auth_provider.dart';
import '../../core/constants/app_theme.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> with SingleTickerProviderStateMixin {
  String _pin = "";
  String _confirmPin = "";
  bool _isConfirming = false;
  String _errorMessage = "";

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
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String val) {
    setState(() {
      _errorMessage = "";
      if (val == "back") {
        if (!_isConfirming && _pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        } else if (_isConfirming && _confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (!_isConfirming && _pin.length < 6) {
          _pin += val;
          if (_pin.length == 6) {
            // Delay slightly for visual feedback before transition
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                setState(() {
                  _isConfirming = true;
                });
              }
            });
          }
        } else if (_isConfirming && _confirmPin.length < 6) {
          _confirmPin += val;
          if (_confirmPin.length == 6) {
            Future.delayed(const Duration(milliseconds: 200), _handlePinVerification);
          }
        }
      }
    });
  }

  void _handlePinVerification() async {
    if (_pin == _confirmPin) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.setupPin(_pin);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } else {
      // Shake animation and reset
      _shakeController.forward(from: 0.0);
      setState(() {
        _errorMessage = "PINs do not match. Please try again.";
        _confirmPin = "";
        _pin = "";
        _isConfirming = false;
      });
    }
  }

  Widget _buildDot(int index) {
    final active = _isConfirming ? index < _confirmPin.length : index < _pin.length;
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

  Widget _buildDialpad() {
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
            const SizedBox(width: 75), // Spacer for align
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
                'ENCRYPTION ACTIVE: AES-256',
                style: TextStyle(
                  color: AppColors.darkPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              // Title / Action Message
              Text(
                _isConfirming ? 'Confirm Security PIN' : 'Create Security PIN',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isConfirming
                    ? 'Re-enter your 6-digit PIN to verify'
                    : 'Set a 6-digit passcode to lock this device',
                style: const TextStyle(
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
                ),
              const Spacer(flex: 2),
              // Dialpad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: _buildDialpad(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
