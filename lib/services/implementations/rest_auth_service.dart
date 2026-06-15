import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/auth_exception.dart';
import '../../core/auth_result.dart';
import '../../core/auth_type.dart';
import '../../models/auth_credentials.dart';
import '../../models/user_model.dart';
import '../auth_service.dart';

class RestAuthService extends AuthService {
  static const Duration defaultTimeout = Duration(seconds: 15);

  final String baseUrl;
  final http.Client _client;
  final Duration timeout;
  String? _token;

  RestAuthService({
    required this.baseUrl,
    http.Client? client,
    this.timeout = defaultTimeout,
  }) : _client = client ?? http.Client() {
    _validateBaseUrl(baseUrl);
  }

  /// Indicates whether the service currently has a bearer token.
  ///
  /// The token itself intentionally stays private to reduce accidental leaks and
  /// prevent session fixation through arbitrary token injection.
  bool get hasSession => _token != null;

  void _validateBaseUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw ArgumentError('Invalid baseUrl: $url');
    }
    final isLocalhost =
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '10.0.2.2';
    if (uri.scheme != 'https' && !isLocalhost) {
      throw ArgumentError(
        'Insecure baseUrl scheme "${uri.scheme}". baseUrl must use HTTPS in production to prevent credential exposure.',
      );
    }
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  void _extractAndSaveToken(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      if (data is Map<String, dynamic>) {
        final nestedData = data['data'];
        final token =
            data['token'] as String? ??
            data['accessToken'] as String? ??
            (nestedData is Map<String, dynamic>
                ? nestedData['token'] as String?
                : null);
        if (token != null && token.trim().isNotEmpty) {
          _token = token;
        }
      }
    } catch (_) {
      // Ignore parsing errors here; already handled in _handleResponse
    }
  }

  @override
  Future<AuthResult<UserModel>> register(
    RegisterCredentials credentials,
  ) async {
    try {
      final body = <String, dynamic>{
        'password': credentials.password,
        'displayName': credentials.displayName,
      };
      if (credentials.email != null) {
        body['email'] = credentials.email;
      }
      if (credentials.phoneNumber != null) {
        body['phoneNumber'] = credentials.phoneNumber;
      }

      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/register'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
      final result = _handleResponse<UserModel>(response, UserModel.fromMap);
      if (result.isSuccess) {
        _extractAndSaveToken(response.body);
      }
      return result;
    } catch (e) {
      return AuthResult<UserModel>.failure(_networkError(e));
    }
  }

  @override
  Future<AuthResult<UserModel>> login(LoginCredentials credentials) async {
    try {
      final body = <String, dynamic>{'password': credentials.password};
      if (credentials.email != null) {
        body['email'] = credentials.email;
      }
      if (credentials.phoneNumber != null) {
        body['phoneNumber'] = credentials.phoneNumber;
      }

      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
      final result = _handleResponse<UserModel>(response, UserModel.fromMap);
      if (result.isSuccess) {
        _extractAndSaveToken(response.body);
      }
      return result;
    } catch (e) {
      return AuthResult.failure(_networkError(e));
    }
  }

  @override
  Future<AuthResult<void>> sendOtp(String contact, AuthMethod method) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/send-otp'),
            headers: _headers,
            body: jsonEncode({'contact': contact, 'method': method.name}),
          )
          .timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      return AuthResult.failure(_networkError(e));
    }
  }

  @override
  Future<AuthResult<bool>> verifyOtp(
    String contact,
    String otp,
    AuthMethod method,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: _headers,
            body: jsonEncode({
              'contact': contact,
              'otp': otp,
              'method': method.name,
            }),
          )
          .timeout(timeout);
      final result = _handleResponse<Map<String, dynamic>>(
        response,
        (json) => json,
      );
      return result.fold(
        (data) => AuthResult.success(data['verified'] as bool? ?? false),
        (error) => AuthResult.failure(error),
      );
    } catch (e) {
      return AuthResult.failure(_networkError(e));
    }
  }

  @override
  Future<AuthResult<void>> resendOtp(String contact, AuthMethod method) async {
    return sendOtp(contact, method);
  }

  @override
  Future<AuthResult<void>> forgotPassword(String email) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/forgot-password'),
            headers: _headers,
            body: jsonEncode({'email': email}),
          )
          .timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      return AuthResult.failure(_networkError(e));
    }
  }

  @override
  Future<AuthResult<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/auth/reset-password'),
            headers: _headers,
            body: jsonEncode({'token': token, 'newPassword': newPassword}),
          )
          .timeout(timeout);
      return _handleResponse(response);
    } catch (e) {
      return AuthResult.failure(_networkError(e));
    }
  }

  @override
  Future<AuthResult<void>> logout() async {
    try {
      final response = await _client
          .post(Uri.parse('$baseUrl/auth/logout'), headers: _headers)
          .timeout(timeout);
      _token = null;
      return _handleResponse(response);
    } catch (e) {
      _token = null;
      return AuthResult.failure(_networkError(e));
    }
  }

  @override
  Future<AuthResult<UserModel?>> getCurrentUser() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/auth/me'), headers: _headers)
          .timeout(timeout);
      if (response.statusCode == 401) return const AuthResult.success(null);
      return _handleResponse<UserModel?>(
        response,
        (json) => UserModel.fromMap(json),
      );
    } catch (e) {
      return AuthResult.failure(_networkError(e));
    }
  }

  @override
  Future<AuthResult<UserModel>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (displayName != null) body['displayName'] = displayName;
      if (photoUrl != null) body['photoUrl'] = photoUrl;

      final response = await _client
          .patch(
            Uri.parse('$baseUrl/auth/profile'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return _handleResponse<UserModel>(response, UserModel.fromMap);
    } catch (e) {
      return AuthResult.failure(_networkError(e));
    }
  }

  AuthResult<T> _handleResponse<T>(
    http.Response response, [
    T Function(Map<String, dynamic>)? fromJson,
  ]) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    if (isSuccess && response.body.isEmpty) {
      return const AuthResult.success(null) as AuthResult<T>;
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      final errorMsg =
          'Server error (${response.statusCode}): ${response.reasonPhrase ?? "Invalid JSON response"}';
      return AuthResult<T>.failure(
        AuthException(errorMsg, code: 'server-error'),
      );
    }

    if (isSuccess) {
      if (fromJson != null) {
        return AuthResult.success(fromJson(body));
      }
      return const AuthResult.success(null) as AuthResult<T>;
    }

    final message = _safeErrorMessage(
      response.statusCode,
      body['message'] as String?,
    );
    final code = body['code'] as String?;
    return AuthResult<T>.failure(AuthException(message, code: code));
  }

  String _safeErrorMessage(int statusCode, String? serverMessage) {
    if (statusCode == 401 || statusCode == 403) {
      return 'Authentication failed. Please sign in again.';
    }
    if (statusCode == 404) {
      return 'The requested authentication resource was not found.';
    }
    if (statusCode >= 500) {
      return 'Authentication service is temporarily unavailable.';
    }
    final message = serverMessage?.trim();
    return message == null || message.isEmpty
        ? 'Authentication request failed.'
        : message;
  }

  AuthException _networkError(Object error) {
    if (error is TimeoutException) {
      return const AuthException(
        'Authentication request timed out. Please try again.',
        code: 'timeout',
      );
    }
    return const AuthException(
      'Unable to reach the authentication service. Please try again.',
      code: 'network-error',
    );
  }

  void dispose() => _client.close();
}
