import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_auth_kit/flutter_auth_kit.dart';

void main() {
  group('AuthResult', () {
    test('success result', () {
      final result = AuthResult<String>.success('hello');
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.data, 'hello');
    });

    test('failure result', () {
      final result = AuthResult<String>.failure(AuthException('error'));
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.error, isA<AuthException>());
    });

    test('fold success', () {
      final result = AuthResult<int>.success(42);
      final value = result.fold((data) => data, (error) => -1);
      expect(value, 42);
    });

    test('fold failure', () {
      final result = AuthResult<int>.failure(AuthException('fail'));
      final value = result.fold((data) => data, (error) => -1);
      expect(value, -1);
    });
  });

  group('EmailValidator', () {
    test('valid email', () {
      expect(EmailValidator.validate('user@example.com'), isNull);
    });

    test('invalid email', () {
      expect(EmailValidator.validate('not-an-email'), isNotNull);
    });

    test('empty email', () {
      expect(EmailValidator.validate(''), isNotNull);
    });

    test('null email', () {
      expect(EmailValidator.validate(null), isNotNull);
    });
  });

  group('PhoneValidator', () {
    test('valid phone with plus', () {
      expect(PhoneValidator.validate('+1234567890'), isNull);
    });

    test('invalid phone', () {
      expect(PhoneValidator.validate('abc'), isNotNull);
    });

    test('empty phone', () {
      expect(PhoneValidator.validate(''), isNotNull);
    });
  });

  group('UserModel', () {
    test('toMap and fromMap round trip', () {
      final user = UserModel(
        uid: '123',
        email: 'test@test.com',
        displayName: 'Test User',
        isEmailVerified: true,
      );
      final map = user.toMap();
      final restored = UserModel.fromMap(map);
      expect(restored.uid, '123');
      expect(restored.email, 'test@test.com');
      expect(restored.displayName, 'Test User');
      expect(restored.isEmailVerified, true);
    });

    test('copyWith preserves unset fields', () {
      final user = UserModel(uid: '1', email: 'a@b.com');
      final copied = user.copyWith(displayName: 'New Name');
      expect(copied.uid, '1');
      expect(copied.email, 'a@b.com');
      expect(copied.displayName, 'New Name');
    });
  });

  group('AuthException', () {
    test('fromFirebase maps user-not-found', () {
      final e = Exception('[firebase_auth/user-not-found] No user found');
      final exc = AuthException.fromFirebase(e);
      expect(exc.code, 'user-not-found');
    });

    test('fromFirebase maps wrong-password', () {
      final e = Exception('[firebase_auth/wrong-password] Wrong password');
      final exc = AuthException.fromFirebase(e);
      expect(exc.code, 'wrong-password');
    });
  });
}
