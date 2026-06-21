import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';
import 'auth_state.dart';
import '../core/utils/app_logger.dart';
import '../data/database/db_helper.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  AuthState _state = AuthState.initial();
  AuthState get state => _state;

  bool get isAuthenticated => _state.status == AuthStatus.authenticated;
  bool get isLoading => _state.status == AuthStatus.loading;
  
  // Compatibility getters/setters for settings & other components
  bool get isDecoyMode => false;
  bool get isBiometricEnabled => false;
  Duration get autoLockDuration => const Duration(minutes: 5);

  AuthProvider() {
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
  }

  Future<void> checkSession() async {
    _state = AuthState.loading("Restoring Session...");
    notifyListeners();

    try {
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
        await DBHelper.instance.initDatabase(isDecoy: false, password: vaultKey);
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
        await DBHelper.instance.initDatabase(isDecoy: false, password: password);
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
        // Auto-login setting storage
        await _secureStorage.write(key: 'secure_vault_key', value: password);
        await DBHelper.instance.initDatabase(isDecoy: false, password: password);
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
      await DBHelper.instance.closeDatabase();
      _state = AuthState.unauthenticated();
    } catch (e) {
      _state = AuthState.unauthenticated();
    }
    notifyListeners();
  }

  // Compatibility stubs for SettingsScreen / older components
  Future<String> setupMasterPassword(String password) async => 'YN-DUMMY-RECOVERY-KEY';
  Future<bool> changeMasterPassword(String oldPassword, String newPassword) async => true;
  Future<void> changeDecoyPassword(String newDecoyPassword) async {}
  Future<void> setBiometricsEnabled(bool enabled, String currentPassword) async {}
  Future<void> updateAutoLockDuration(Duration duration) async {}
}
