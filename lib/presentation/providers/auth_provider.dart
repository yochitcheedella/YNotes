import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/security/auto_lock_service.dart';
import '../../core/security/encryption_service.dart';
import '../../core/utils/app_logger.dart';
import '../../data/database/db_helper.dart';

class AuthProvider with ChangeNotifier {
  static const _secureStorageOptions = AndroidOptions(encryptedSharedPreferences: true);

  final _secureStorage = const FlutterSecureStorage(aOptions: _secureStorageOptions);
  final _localAuth = LocalAuthentication();

  bool _isOnboarded = false;
  bool _isAuthenticated = false;
  bool _isDecoyMode = false;
  bool _isBiometricEnabled = false;
  bool _isInitialized = false;
  Duration _autoLockDuration = const Duration(minutes: 1);

  bool get isOnboarded => _isOnboarded;
  bool get isAuthenticated => _isAuthenticated;
  bool get isDecoyMode => _isDecoyMode;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isInitialized => _isInitialized;
  Duration get autoLockDuration => _autoLockDuration;

  AuthProvider() {
    _initAuthState();
  }

  Future<void> _initAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboarded = prefs.getBool('is_onboarded') ?? false;

      final bioEnabledStr = await _secureStorage.read(key: 'biometric_enabled');
      _isBiometricEnabled = bioEnabledStr == 'true';

      final lockSecs = prefs.getInt('auto_lock_seconds') ?? 60;
      _autoLockDuration = Duration(seconds: lockSecs);

      AppLogger.info('Auth state initialized. Onboarded: $_isOnboarded, Biometric: $_isBiometricEnabled');
    } catch (e) {
      AppLogger.error('Failed to initialize auth state', exception: e);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// First-time setup: stores password hash + recovery key, returns recovery key.
  Future<String> setupMasterPassword(String password) async {
    // Store salted PBKDF2 hash (new format)
    final hash = EncryptionService.hashPassword(password);
    await _secureStorage.write(key: 'master_password_hash', value: hash);

    // Default decoy password
    final decoyHash = EncryptionService.hashPassword('Demo@123');
    await _secureStorage.write(key: 'decoy_password_hash', value: decoyHash);

    // Generate recovery key and wrap master password with it
    final recoveryKey = EncryptionService.generateRecoveryKey();
    await _secureStorage.write(key: 'recovery_key', value: recoveryKey);
    final wrapped = EncryptionService.encryptText(password, recoveryKey);
    await _secureStorage.write(key: 'master_password_wrapped', value: wrapped);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);
    _isOnboarded = true;

    AppLogger.security('Master password configured during onboarding');
    await authenticate(password);
    return recoveryKey;
  }

  /// Recover master password using the backup recovery key.
  Future<String?> recoverPassword(String recoveryKeyInput) async {
    try {
      final wrapped = await _secureStorage.read(key: 'master_password_wrapped');
      if (wrapped == null) return null;

      final plainPassword = EncryptionService.decryptText(wrapped, recoveryKeyInput.trim().toUpperCase());
      // Verify the decrypted password matches the stored hash
      final storedHash = await _secureStorage.read(key: 'master_password_hash');
      if (storedHash != null && EncryptionService.verifyPassword(plainPassword, storedHash)) {
        AppLogger.security('Password recovered via recovery key');
        return plainPassword;
      }
    } catch (e) {
      AppLogger.error('Recovery decryption failed', exception: e);
    }
    return null;
  }

  /// Authenticate with master or decoy password.
  Future<bool> authenticate(String password) async {
    try {
      final realHash = await _secureStorage.read(key: 'master_password_hash');
      final decoyHash = await _secureStorage.read(key: 'decoy_password_hash');

      if (realHash != null && EncryptionService.verifyPassword(password, realHash)) {
        _isDecoyMode = false;
        await DBHelper.instance.initDatabase(isDecoy: false, password: password);

        if (_isBiometricEnabled) {
          // Store plaintext password securely for biometric unlock only
          await _secureStorage.write(key: 'master_password_plain', value: password);
        }

        _completeLogin();
        AppLogger.security('User authenticated (real vault)');
        return true;
      } else if (decoyHash != null && EncryptionService.verifyPassword(password, decoyHash)) {
        _isDecoyMode = true;
        await DBHelper.instance.initDatabase(isDecoy: true, password: password);
        _completeLogin();
        AppLogger.security('User authenticated (decoy vault)');
        return true;
      }
    } catch (e) {
      AppLogger.error('Authentication error', exception: e);
    }

    AppLogger.security('Failed authentication attempt');
    return false;
  }

  void _completeLogin() {
    _isAuthenticated = true;
    AutoLockService.instance.initialize(
      initialDuration: _autoLockDuration,
      onLockTriggered: () => logout(),
    );
    notifyListeners();
  }

  /// Biometric authentication path.
  Future<bool> authenticateBiometrics() async {
    if (!_isBiometricEnabled) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Verify fingerprint to unlock YNote 🔐',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );

      if (didAuthenticate) {
        final plainPassword = await _secureStorage.read(key: 'master_password_plain');
        if (plainPassword != null) {
          _isDecoyMode = false;
          await DBHelper.instance.initDatabase(isDecoy: false, password: plainPassword);
          _completeLogin();
          AppLogger.security('User authenticated via biometrics');
          return true;
        }
      }
    } catch (e) {
      AppLogger.error('Biometric authentication error', exception: e);
    }
    return false;
  }

  /// Enable or disable biometric unlock.
  /// When enabling, requires the current password for verification.
  /// When disabling, no password is needed.
  Future<void> setBiometricsEnabled(bool enabled, String currentPassword) async {
    if (enabled) {
      // Require password verification before enabling
      final storedHash = await _secureStorage.read(key: 'master_password_hash');
      if (storedHash == null || !EncryptionService.verifyPassword(currentPassword, storedHash)) {
        throw Exception('Incorrect Master Password');
      }
      await _secureStorage.write(key: 'master_password_plain', value: currentPassword);
      AppLogger.security('Biometric authentication ENABLED');
    } else {
      // Disabling biometrics: delete stored plaintext password for security
      await _secureStorage.delete(key: 'master_password_plain');
      AppLogger.security('Biometric authentication DISABLED');
    }

    _isBiometricEnabled = enabled;
    await _secureStorage.write(key: 'biometric_enabled', value: enabled.toString());
    notifyListeners();
  }

  /// Change master password — re-hashes, re-wraps recovery key, re-opens DB.
  Future<bool> changeMasterPassword(String oldPassword, String newPassword) async {
    final storedHash = await _secureStorage.read(key: 'master_password_hash');
    if (storedHash == null || !EncryptionService.verifyPassword(oldPassword, storedHash)) {
      return false;
    }

    final newHash = EncryptionService.hashPassword(newPassword);
    await _secureStorage.write(key: 'master_password_hash', value: newHash);

    final recoveryKey = await _secureStorage.read(key: 'recovery_key');
    if (recoveryKey != null) {
      final wrapped = EncryptionService.encryptText(newPassword, recoveryKey);
      await _secureStorage.write(key: 'master_password_wrapped', value: wrapped);
    }

    if (_isBiometricEnabled) {
      await _secureStorage.write(key: 'master_password_plain', value: newPassword);
    }

    if (!_isDecoyMode) {
      await DBHelper.instance.initDatabase(isDecoy: false, password: newPassword);
    }

    AppLogger.security('Master password changed successfully');
    notifyListeners();
    return true;
  }

  /// Update the decoy password.
  Future<void> changeDecoyPassword(String newDecoyPassword) async {
    final hash = EncryptionService.hashPassword(newDecoyPassword);
    await _secureStorage.write(key: 'decoy_password_hash', value: hash);
    AppLogger.security('Decoy password updated');
    notifyListeners();
  }

  /// Update the auto-lock inactivity duration.
  Future<void> updateAutoLockDuration(Duration duration) async {
    _autoLockDuration = duration;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_lock_seconds', duration.inSeconds);
    AutoLockService.instance.updateDuration(duration);
    notifyListeners();
  }

  /// Log out and close the database.
  Future<void> logout() async {
    await DBHelper.instance.closeDatabase();
    AutoLockService.instance.dispose();
    _isAuthenticated = false;
    _isDecoyMode = false;
    AppLogger.security('User logged out and vault closed');
    notifyListeners();
  }
}
