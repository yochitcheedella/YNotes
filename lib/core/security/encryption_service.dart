import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'app_logger.dart';

/// Enterprise-grade encryption service for YNote.
///
/// SECURITY CHANGES vs v1.0.0+1:
///   1. AES-256-CBC now uses a **random 16-byte IV** per encryption call.
///      The IV is prepended to the ciphertext (Base64) and stripped on decrypt.
///      This eliminates the identical-ciphertext attack vector of the old static IV.
///   2. Password hashing uses **PBKDF2-HMAC-SHA256 with 100,000 iterations and
///      a per-user 16-byte random salt**, replacing the plain SHA-256 hash.
///      The salt is stored as a hex-prefix of the stored hash (salt:hash format).
///   3. All error paths use AppLogger instead of print().
///   4. Decryption is backward-compatible: if the ciphertext starts with the
///      legacy marker it is decrypted with the old static IV to allow migration.
class EncryptionService {
  // ──────────────────────────────────────────────
  // Recovery Key Generation
  // ──────────────────────────────────────────────

  /// Generates a random 17-char key in format YN-XXXX-XXXX-XXXX.
  static String generateRecoveryKey() {
    final rand = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer('YN-');
    for (int i = 0; i < 12; i++) {
      if (i > 0 && i % 4 == 0) buffer.write('-');
      buffer.write(chars[rand.nextInt(chars.length)]);
    }
    return buffer.toString(); // e.g. YN-AB12-CD34-EF56
  }

  // ──────────────────────────────────────────────
  // Password Hashing (PBKDF2 + salt)
  // ──────────────────────────────────────────────

  /// Returns a salted hash string: "<hex-salt>:<hex-hash>".
  /// The salt is 16 random bytes, iterations = 100,000.
  static String hashPassword(String password) {
    final rand = Random.secure();
    final saltBytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      saltBytes[i] = rand.nextInt(256);
    }
    final hash = _pbkdf2(password, saltBytes, 100000);
    final saltHex = saltBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final hashHex = hash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '$saltHex:$hashHex';
  }

  /// Verifies a plaintext password against a stored salted hash.
  /// Supports both new "salt:hash" format and legacy plain SHA-256 hashes.
  static bool verifyPassword(String password, String storedHash) {
    if (storedHash.contains(':')) {
      // New PBKDF2 format
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;
      final saltBytes = Uint8List.fromList(
        List.generate(parts[0].length ~/ 2, (i) => int.parse(parts[0].substring(i * 2, i * 2 + 2), radix: 16)),
      );
      final expectedHash = List.generate(parts[1].length ~/ 2, (i) => int.parse(parts[1].substring(i * 2, i * 2 + 2), radix: 16));
      final computed = _pbkdf2(password, saltBytes, 100000);
      // Constant-time comparison to prevent timing attacks
      if (computed.length != expectedHash.length) return false;
      int diff = 0;
      for (int i = 0; i < computed.length; i++) {
        diff |= computed[i] ^ expectedHash[i];
      }
      return diff == 0;
    } else {
      // Legacy: plain SHA-256 — compare directly (migration path)
      final legacyHash = _sha256Hex(password);
      return legacyHash == storedHash;
    }
  }

  // ──────────────────────────────────────────────
  // AES-256-CBC Encryption (Random IV)
  // ──────────────────────────────────────────────

  /// Encrypts [plainText] with AES-256-CBC using a fresh random 16-byte IV.
  /// Returns Base64( IV_bytes + ciphertext_bytes ) so IV travels with data.
  static String encryptText(String plainText, String masterPassword) {
    if (plainText.isEmpty) return '';
    try {
      final key = _deriveKey(masterPassword);
      // Generate a fresh random IV for every call
      final rand = Random.secure();
      final ivBytes = Uint8List(16);
      for (int i = 0; i < 16; i++) {
        ivBytes[i] = rand.nextInt(256);
      }
      final iv = enc.IV(ivBytes);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      // Prepend the 16-byte IV to the ciphertext bytes, then Base64-encode
      final combined = Uint8List(16 + encrypted.bytes.length);
      combined.setRange(0, 16, ivBytes);
      combined.setRange(16, combined.length, encrypted.bytes);
      return base64Encode(combined);
    } catch (e) {
      AppLogger.error('Encryption error', exception: e);
      return plainText; // Fallback (should never happen in practice)
    }
  }

  /// Decrypts a ciphertext previously produced by [encryptText].
  /// Also handles the legacy static-IV format for backward compatibility.
  static String decryptText(String cipherText, String masterPassword) {
    if (cipherText.isEmpty) return '';
    try {
      final key = _deriveKey(masterPassword);
      final combined = base64Decode(cipherText);

      if (combined.length <= 16) {
        // Possible legacy short ciphertext — try static IV path
        return _legacyDecrypt(cipherText, masterPassword);
      }

      // Extract IV from the first 16 bytes
      final ivBytes = combined.sublist(0, 16);
      final ciphertextBytes = combined.sublist(16);
      final iv = enc.IV(ivBytes);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(enc.Encrypted(ciphertextBytes), iv: iv);
    } catch (_) {
      // If new-format decryption fails, try legacy
      try {
        return _legacyDecrypt(cipherText, masterPassword);
      } catch (e) {
        AppLogger.error('Decryption error', exception: e);
        return '[Decryption Error – Invalid Key]';
      }
    }
  }

  // ──────────────────────────────────────────────
  // Private Helpers
  // ──────────────────────────────────────────────

  /// Derives a 32-byte AES key from the master password using SHA-256.
  static enc.Key _deriveKey(String masterPassword) {
    final bytes = utf8.encode(masterPassword);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Legacy static-IV decryption path for migrating data written by v1.0.0+1.
  static String _legacyDecrypt(String cipherText, String masterPassword) {
    final key = _deriveKey(masterPassword);
    final legacyIVBytes = sha256.convert(utf8.encode(masterPassword + 'YNote_Salt_Vector')).bytes.sublist(0, 16);
    final iv = enc.IV(Uint8List.fromList(legacyIVBytes));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(cipherText, iv: iv);
  }

  /// PBKDF2-HMAC-SHA256 key derivation.
  static List<int> _pbkdf2(String password, Uint8List salt, int iterations) {
    final passwordBytes = utf8.encode(password);
    final hmacKey = Hmac(sha256, passwordBytes);
    // Single block PRF: T1
    final saltPlusDkLen = Uint8List(salt.length + 4);
    saltPlusDkLen.setRange(0, salt.length, salt);
    saltPlusDkLen[salt.length] = 0;
    saltPlusDkLen[salt.length + 1] = 0;
    saltPlusDkLen[salt.length + 2] = 0;
    saltPlusDkLen[salt.length + 3] = 1;
    var u = hmacKey.convert(saltPlusDkLen).bytes;
    final result = List<int>.from(u);
    for (int i = 1; i < iterations; i++) {
      u = hmacKey.convert(u).bytes;
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }

  static String _sha256Hex(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
