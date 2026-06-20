import 'package:flutter_test/flutter_test.dart';
import 'package:diaro/core/utils/input_validator.dart';

void main() {
  group('InputValidator Tests', () {
    group('masterPassword', () {
      test('should return error when password is empty', () {
        expect(InputValidator.masterPassword(null), 'Password is required');
        expect(InputValidator.masterPassword(''), 'Password is required');
      });

      test('should return error when password is less than 8 characters', () {
        expect(InputValidator.masterPassword('Ab1'), 'Password must be at least 8 characters');
        expect(InputValidator.masterPassword('Abc1234'), 'Password must be at least 8 characters');
      });

      test('should return error when password has no uppercase letter', () {
        expect(InputValidator.masterPassword('abc12345'), 'Password must contain at least one uppercase letter');
      });

      test('should return error when password has no digit', () {
        expect(InputValidator.masterPassword('Abcdefgh'), 'Password must contain at least one digit');
      });

      test('should return null when password is valid', () {
        expect(InputValidator.masterPassword('ValidPass123'), isNull);
        expect(InputValidator.masterPassword('Secure@2026'), isNull);
      });
    });

    group('newPassword', () {
      test('should return error when new password is same as current password', () {
        expect(
          InputValidator.newPassword('ValidPass123', currentPassword: 'ValidPass123'),
          'New password must differ from the current password',
        );
      });

      test('should return null when new password is valid and different', () {
        expect(
          InputValidator.newPassword('NewSecure@2026', currentPassword: 'ValidPass123'),
          isNull,
        );
      });
    });

    group('recoveryKey', () {
      test('should return error when recovery key is empty', () {
        expect(InputValidator.recoveryKey(null), 'Recovery key is required');
        expect(InputValidator.recoveryKey(''), 'Recovery key is required');
      });

      test('should return error when recovery key format is invalid', () {
        expect(InputValidator.recoveryKey('invalid-key'), 'Invalid key format. Expected: YN-XXXX-XXXX-XXXX');
        expect(InputValidator.recoveryKey('YN-ABCD-EFGH-IJK'), 'Invalid key format. Expected: YN-XXXX-XXXX-XXXX');
        expect(InputValidator.recoveryKey('YN-123-4567-8901'), 'Invalid key format. Expected: YN-XXXX-XXXX-XXXX');
      });

      test('should return null when recovery key is valid', () {
        expect(InputValidator.recoveryKey('YN-ABCD-EF12-34GH'), isNull);
        expect(InputValidator.recoveryKey('yn-abcd-ef12-34gh'), isNull); // Case-insensitive trim check
      });
    });

    group('entryTitle', () {
      test('should return error when title is empty', () {
        expect(InputValidator.entryTitle(null), 'Title is required');
        expect(InputValidator.entryTitle(''), 'Title is required');
        expect(InputValidator.entryTitle('   '), 'Title is required');
      });

      test('should return error when title is too long', () {
        final longTitle = 'a' * 101;
        expect(InputValidator.entryTitle(longTitle), 'Title must be 100 characters or fewer');
      });

      test('should return null when title is valid', () {
        expect(InputValidator.entryTitle('My Secure Diary'), isNull);
      });
    });

    group('entryContent', () {
      test('should return error when content is empty', () {
        expect(InputValidator.entryContent(null), 'Content cannot be empty');
        expect(InputValidator.entryContent(''), 'Content cannot be empty');
        expect(InputValidator.entryContent('   '), 'Content cannot be empty');
      });

      test('should return null when content is valid', () {
        expect(InputValidator.entryContent('Today was a great day!'), isNull);
      });
    });

    group('shortPassword', () {
      test('should return error when short password is empty', () {
        expect(InputValidator.shortPassword(null), 'Password is required');
        expect(InputValidator.shortPassword(''), 'Password is required');
      });

      test('should return error when short password is less than 6 characters', () {
        expect(InputValidator.shortPassword('12345'), 'Must be at least 6 characters');
      });

      test('should return null when short password is valid', () {
        expect(InputValidator.shortPassword('123456'), isNull);
        expect(InputValidator.shortPassword('Demo@123'), isNull);
      });
    });
  });
}
