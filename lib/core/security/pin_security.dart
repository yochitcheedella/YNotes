import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class PinSecurity {
  /// Generate random 16-byte salt (Base64 URL encoded)
  static String generateSalt() {
    final rand = Random.secure();
    final values = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(values);
  }

  /// PBKDF2 hash
  static String hashPin(String pin, String salt) {
    final keyBytes = pbkdf2(pin, salt, 100000, 32);
    return base64UrlEncode(keyBytes);
  }

  /// Verification
  static bool verifyPin(String pin, String salt, String storedHash) {
    final newHash = hashPin(pin, salt);
    // Constant-time comparison to prevent timing attacks
    if (newHash.length != storedHash.length) return false;
    int diff = 0;
    for (int i = 0; i < newHash.length; i++) {
      diff |= newHash.codeUnitAt(i) ^ storedHash.codeUnitAt(i);
    }
    return diff == 0;
  }

  /// PBKDF2 implementation (Synchronous, Pure Dart, using crypto's HMAC-SHA256)
  static List<int> pbkdf2(
    String password,
    String salt,
    int iterations,
    int keyLength,
  ) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = base64Url.decode(salt);

    final hmac = Hmac(sha256, passwordBytes);
    final hLen = 32; // SHA-256 output length in bytes
    final l = (keyLength / hLen).ceil();
    final r = keyLength - (l - 1) * hLen;
    final dk = Uint8List(keyLength);

    var offset = 0;
    for (var i = 1; i <= l; i++) {
      final saltAndI = Uint8List(saltBytes.length + 4);
      saltAndI.setRange(0, saltBytes.length, saltBytes);
      
      // Write i as 32-bit big-endian integer
      saltAndI[saltBytes.length] = (i >> 24) & 0xff;
      saltAndI[saltBytes.length + 1] = (i >> 16) & 0xff;
      saltAndI[saltBytes.length + 2] = (i >> 8) & 0xff;
      saltAndI[saltBytes.length + 3] = i & 0xff;

      var u = hmac.convert(saltAndI).bytes;
      final block = Uint8List.fromList(u);

      for (var j = 1; j < iterations; j++) {
        u = hmac.convert(u).bytes;
        for (var k = 0; k < hLen; k++) {
          block[k] ^= u[k];
        }
      }

      final len = (i == l) ? r : hLen;
      dk.setRange(offset, offset + len, block);
      offset += len;
    }
    return dk;
  }
}
