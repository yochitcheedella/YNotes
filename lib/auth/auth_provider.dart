import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';
import 'auth_state.dart';
import '../core/utils/app_logger.dart';
import '../data/database/db_helper.dart';
import '../core/security/pin_security.dart';
import '../core/security/auto_lock_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  AuthState _state = AuthState.initial();
  AuthState get state => _state;

  bool get isAuthenticated => _state.status == AuthStatus.authenticated;
  bool get isLoading => _state.status == AuthStatus.loading;
  
  // PIN & Security settings
  bool _hasPin = false;
  bool get hasPin => _hasPin;

  bool _isLocked = true;
  bool get isLocked => _isLocked;

  bool _isBiometricEnabled = false;
  bool get isBiometricEnabled => _isBiometricEnabled;

  Duration _autoLockDuration = const Duration(minutes: 5);
  Duration get autoLockDuration => _autoLockDuration;

  // Compatibility getters/setters
  bool get isDecoyMode => false;

  AuthProvider() {
    _loadSettings().then((_) {
      // Listen to Supabase session change
      _authService.onAuthStateChange.listen((authState) async {
        if (authState.status == AuthStatus.authenticated) {
          final success = await _initializeLocalDb();
          if (success) {
            _state = authState;
          } else {
            _state = AuthState.unauthenticated();
          }
        } else {
          _state = authState;
        }
        notifyListeners();
      });
    });
  }

  Future<void> _loadSettings() async {
    try {
      final durationStr = await _secureStorage.read(key: 'auto_lock_duration_seconds');
      if (durationStr != null) {
        final seconds = int.tryParse(durationStr);
        if (seconds != null) {
          _autoLockDuration = Duration(seconds: seconds);
        }
      }
      final bioEnabledStr = await _secureStorage.read(key: 'biometrics_enabled');
      _isBiometricEnabled = bioEnabledStr == 'true';

      final hash = await _secureStorage.read(key: 'pin_hash');
      _hasPin = hash != null;
      // If we have a PIN set up, we start in a locked state.
      _isLocked = _hasPin;
    } catch (e) {
      AppLogger.error("Failed to load settings in AuthProvider", exception: e);
    }
  }

  Future<void> checkSession() async {
    _state = AuthState.loading("Restoring Session...");
    notifyListeners();

    try {
      await _loadSettings();
      final session = _authService.currentSession;
      if (session != null) {
        final success = await _initializeLocalDb();
        if (success) {
          _state = AuthState.authenticated();
        } else {
          _state = AuthState.unauthenticated();
        }
      } else {
        _state = AuthState.unauthenticated();
      }
    } catch (e) {
      _state = AuthState.unauthenticated();
    }
    notifyListeners();
  }

  Future<bool> _initializeLocalDb() async {
    final vaultKey = await _secureStorage.read(key: 'secure_vault_key');
    if (vaultKey != null) {
      try {
        await DBHelper.instance.initDatabase(isDecoy: false, password: vaultKey, userId: _authService.currentSession?.user.id);
        return true;
      } catch (e) {
        AppLogger.error("Failed to initialize database", exception: e);
      }
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    _state = AuthState.loading("Logging In...");
    notifyListeners();

    try {
      final user = await _authService.signIn(email, password);
      if (user != null) {
        await _secureStorage.write(key: 'secure_vault_key', value: password);
        await DBHelper.instance.initDatabase(isDecoy: false, password: password, userId: user.id);
        await _loadSettings();
        // Since we logged in, if we already have a PIN, unlock immediately.
        _isLocked = false;
        _state = AuthState.authenticated();
        notifyListeners();
        return true;
      }
    } catch (e) {
      String errMsg = "Incorrect email or password.";
      final errStr = e.toString().toLowerCase();
      if (errStr.contains("network") || errStr.contains("connection")) {
        errMsg = "Check your internet connection.";
      } else if (errStr.contains("invalid login credentials")) {
        errMsg = "Incorrect email or password.";
      } else if (errStr.contains("user not found")) {
        errMsg = "No account exists with this email.";
      }
      _state = AuthState.error(errMsg);
      notifyListeners();
    }
    return false;
  }

  Future<bool> signup(String email, String password, String name) async {
    _state = AuthState.loading("Creating Account...");
    notifyListeners();

    try {
      final user = await _authService.signUp(email, password, name);
      if (user != null) {
        await _secureStorage.write(key: 'secure_vault_key', value: password);
        await DBHelper.instance.initDatabase(isDecoy: false, password: password, userId: user.id);
        await _loadSettings();
        _isLocked = false;
        _state = AuthState.authenticated();
        notifyListeners();
        return true;
      }
    } catch (e) {
      String errMsg = "Creating Account failed.";
      final errStr = e.toString().toLowerCase();
      if (errStr.contains("network") || errStr.contains("connection")) {
        errMsg = "Check your internet connection.";
      } else if (errStr.contains("rate limit")) {
        errMsg = "Email rate limit exceeded. Please try again later.";
      }
      _state = AuthState.error(errMsg);
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    _state = AuthState.loading("Logging Out...");
    notifyListeners();
    try {
      await _authService.signOut();
      await _secureStorage.delete(key: 'secure_vault_key');
      await _secureStorage.delete(key: 'pin_hash');
      await _secureStorage.delete(key: 'pin_salt');
      await _secureStorage.delete(key: 'biometrics_enabled');
      _hasPin = false;
      _isLocked = true;
      _isBiometricEnabled = false;
      await DBHelper.instance.closeDatabase();
      _state = AuthState.unauthenticated();
    } catch (e) {
      _state = AuthState.unauthenticated();
    }
    notifyListeners();
  }

  // PIN Operations
  Future<void> setupPin(String pin) async {
    final salt = PinSecurity.generateSalt();
    final hash = PinSecurity.hashPin(pin, salt);
    await _secureStorage.write(key: 'pin_hash', value: hash);
    await _secureStorage.write(key: 'pin_salt', value: salt);
    _hasPin = true;
    _isLocked = false;
    AutoLockService.instance.unlock();
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    final hash = await _secureStorage.read(key: 'pin_hash');
    final salt = await _secureStorage.read(key: 'pin_salt');
    if (hash == null || salt == null) return false;
    final isValid = PinSecurity.verifyPin(pin, salt, hash);
    if (isValid) {
      _isLocked = false;
      AutoLockService.instance.unlock();
      notifyListeners();
    }
    return isValid;
  }

  Future<void> lock() async {
    _isLocked = true;
    notifyListeners();
  }

  Future<void> unlock() async {
    _isLocked = false;
    AutoLockService.instance.unlock();
    notifyListeners();
  }

  Future<void> resetPin() async {
    await _secureStorage.delete(key: 'pin_hash');
    await _secureStorage.delete(key: 'pin_salt');
    _hasPin = false;
    _isLocked = false;
    notifyListeners();
  }

  // Settings & Biometrics
  Future<String> setupMasterPassword(String password) async => 'YN-DUMMY-RECOVERY-KEY';
  Future<bool> changeMasterPassword(String oldPassword, String newPassword) async => true;
  Future<void> changeDecoyPassword(String newDecoyPassword) async {}

  Future<void> setBiometricsEnabled(bool enabled, String currentPassword) async {
    _isBiometricEnabled = enabled;
    await _secureStorage.write(key: 'biometrics_enabled', value: enabled.toString());
    notifyListeners();
  }

  Future<void> updateAutoLockDuration(Duration duration) async {
    _autoLockDuration = duration;
    await _secureStorage.write(key: 'auto_lock_duration_seconds', value: duration.inSeconds.toString());
    AutoLockService.instance.updateDuration(duration);
    notifyListeners();
  }
}
