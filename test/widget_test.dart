import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_auth_kit/flutter_auth_kit.dart';

class MockClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest) requestHandler;

  MockClient(this.requestHandler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await requestHandler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}

class MockAuthService extends AuthService {
  final Future<AuthResult<void>> Function()? onLogout;
  final UserModel? initialUser;

  MockAuthService({this.onLogout, this.initialUser});

  @override
  Future<AuthResult<UserModel>> register(
    RegisterCredentials credentials,
  ) async => throw UnimplementedError();

  @override
  Future<AuthResult<UserModel>> login(LoginCredentials credentials) async =>
      throw UnimplementedError();

  @override
  Future<AuthResult<void>> sendOtp(String contact, AuthMethod method) async =>
      throw UnimplementedError();

  @override
  Future<AuthResult<bool>> verifyOtp(
    String contact,
    String otp,
    AuthMethod method,
  ) async => throw UnimplementedError();

  @override
  Future<AuthResult<void>> resendOtp(String contact, AuthMethod method) async =>
      throw UnimplementedError();

  @override
  Future<AuthResult<void>> forgotPassword(String email) async =>
      throw UnimplementedError();

  @override
  Future<AuthResult<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async => throw UnimplementedError();

  @override
  Future<AuthResult<void>> logout() async {
    if (onLogout != null) return onLogout!();
    return const AuthResult.success(null);
  }

  @override
  Future<AuthResult<UserModel?>> getCurrentUser() async {
    return AuthResult.success(initialUser);
  }

  @override
  Future<AuthResult<UserModel>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async => throw UnimplementedError();
}

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

    test('fromFirebase hides unknown provider details', () {
      final e = Exception(
        '[firebase_auth/internal-error] stack=secret-provider-detail',
      );
      final exc = AuthException.fromFirebase(e);
      expect(exc.code, 'unknown');
      expect(exc.message, 'Authentication failed. Please try again.');
      expect(exc.message, isNot(contains('secret-provider-detail')));
    });
  });

  group('RestAuthService Security & Error Handling', () {
    test('Enforces HTTPS baseUrl', () {
      expect(
        () => RestAuthService(baseUrl: 'http://example.com'),
        throwsArgumentError,
      );

      expect(
        RestAuthService(baseUrl: 'https://example.com').baseUrl,
        'https://example.com',
      );
    });

    test('Allows loopback URLs with HTTP scheme', () {
      expect(
        RestAuthService(baseUrl: 'http://localhost:8080').baseUrl,
        'http://localhost:8080',
      );
      expect(
        RestAuthService(baseUrl: 'http://127.0.0.1:8080').baseUrl,
        'http://127.0.0.1:8080',
      );
      expect(
        RestAuthService(baseUrl: 'http://10.0.2.2:8000').baseUrl,
        'http://10.0.2.2:8000',
      );
    });

    test('Handles non-JSON response body gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          'Internal Server Error HTML',
          500,
          reasonPhrase: 'Internal Server Error',
        );
      });
      final service = RestAuthService(
        baseUrl: 'https://example.com',
        client: mockClient,
      );

      final result = await service.getCurrentUser();
      expect(result.isFailure, true);
      expect(result.error!.message, contains('Server error (500)'));
      expect(result.error!.code, 'server-error');
    });

    test(
      'Stores session internally after successful login without exposing token',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"uid":"user_123","email":"user@test.com","token":"secret-token"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final service = RestAuthService(
          baseUrl: 'https://example.com',
          client: mockClient,
        );

        final result = await service.login(
          const LoginCredentials(
            identifier: 'user@test.com',
            password: 'password123',
          ),
        );

        expect(result.isSuccess, true);
        expect(service.hasSession, true);
      },
    );

    test('Sanitizes unauthorized server messages', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"message":"raw backend auth detail","code":"invalid-token"}',
          401,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = RestAuthService(
        baseUrl: 'https://example.com',
        client: mockClient,
      );

      final result = await service.updateProfile(displayName: 'New Name');

      expect(result.isFailure, true);
      expect(
        result.error!.message,
        'Authentication failed. Please sign in again.',
      );
      expect(result.error!.message, isNot(contains('raw backend auth detail')));
    });

    test('Returns safe timeout error', () async {
      final mockClient = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response('{}', 200);
      });
      final service = RestAuthService(
        baseUrl: 'https://example.com',
        client: mockClient,
        timeout: const Duration(milliseconds: 1),
      );

      final result = await service.getCurrentUser();

      expect(result.isFailure, true);
      expect(result.error!.code, 'timeout');
      expect(result.error!.message, isNot(contains('TimeoutException')));
    });
  });

  group('AuthProvider Security & Usability', () {
    test('Unconditionally clears state on logout failure', () async {
      final testUser = UserModel(uid: 'user_123', email: 'user@test.com');
      final mockService = MockAuthService(
        initialUser: testUser,
        onLogout: () async => const AuthResult.failure(
          AuthException('Network Error', code: 'network-error'),
        ),
      );
      final provider = AuthProvider(mockService);

      // Seed provider with authenticated state
      await provider.initialize();
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user, isNotNull);

      // Perform logout which will fail on the service layer
      final success = await provider.logout();
      expect(success, false);
      expect(provider.error, isNotNull);

      // State must still be cleared
      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
    });
  });
}
