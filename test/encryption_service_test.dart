import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:diaro/core/security/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    const password = 'TestPassword@123';
    const plainText = 'This is a secure diary entry.';

    test('Recovery Key Generation Format', () {
      final key = EncryptionService.generateRecoveryKey();
      expect(key.startsWith('YN-'), isTrue);
      expect(key.length, 17); // YN-XXXX-XXXX-XXXX
      final parts = key.split('-');
      expect(parts.length, 4);
      expect(parts[0], 'YN');
      expect(parts[1].length, 4);
      expect(parts[2].length, 4);
      expect(parts[3].length, 4);
    });

    test('Password Hashing & Verification (PBKDF2)', () {
      final hash = EncryptionService.hashPassword(password);
      expect(hash.contains(':'), isTrue);

      final parts = hash.split(':');
      expect(parts.length, 2);
      expect(parts[0].length, 32); // Hex representation of 16-byte salt
      expect(parts[1].length, 64); // Hex representation of 32-byte hash

      // Correct password verification
      expect(EncryptionService.verifyPassword(password, hash), isTrue);

      // Incorrect password verification
      expect(EncryptionService.verifyPassword('WrongPassword', hash), isFalse);
    });

    test('Legacy SHA-256 Hashing Verification', () {
      // Legacy hash generated via plain SHA-256 hex
      final legacyHash = sha256.convert(utf8.encode(password)).toString();
      
      // Verify legacy compares correctly without ':'
      expect(EncryptionService.verifyPassword(password, legacyHash), isTrue);
      expect(EncryptionService.verifyPassword('WrongPassword', legacyHash), isFalse);
    });

    test('AES Encryption & Decryption (Random IV)', () {
      final encrypted1 = EncryptionService.encryptText(plainText, password);
      final encrypted2 = EncryptionService.encryptText(plainText, password);

      // Ciphertexts must be different for the same plaintext due to random IV
      expect(encrypted1, isNot(equals(encrypted2)));

      // Decryption retrieves original plaintext
      final decrypted1 = EncryptionService.decryptText(encrypted1, password);
      final decrypted2 = EncryptionService.decryptText(encrypted2, password);

      expect(decrypted1, plainText);
      expect(decrypted2, plainText);
    });

    test('Decryption with Incorrect Password returns Error Marker', () {
      final encrypted = EncryptionService.encryptText(plainText, password);
      final decrypted = EncryptionService.decryptText(encrypted, 'WrongPassword');
      expect(decrypted, '[Decryption Error – Invalid Key]');
    });

    test('Decryption Backward Compatibility (Legacy static-IV)', () {
      // Manually encrypt using legacy static-IV method
      final keyBytes = sha256.convert(utf8.encode(password)).bytes;
      final key = enc.Key(Uint8List.fromList(keyBytes));
      
      final legacyIVBytes = sha256.convert(utf8.encode(password + 'Diaro_Salt_Vector')).bytes.sublist(0, 16);
      final iv = enc.IV(Uint8List.fromList(legacyIVBytes));
      
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final legacyCipherText = encrypter.encrypt(plainText, iv: iv).base64;

      // Verify that EncryptionService.decryptText can decrypt this legacy cipherText
      final decrypted = EncryptionService.decryptText(legacyCipherText, password);
      expect(decrypted, plainText);
    });
  });
}
