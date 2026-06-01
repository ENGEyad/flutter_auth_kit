import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/auth_exception.dart';
import '../../core/auth_result.dart';
import '../../core/auth_type.dart';
import '../../models/auth_credentials.dart';
import '../../models/user_model.dart';
import '../auth_service.dart';

class RestAuthService extends AuthService {
  final String baseUrl;
  final http.Client _client;

  RestAuthService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  @override
  Future<AuthResult<UserModel>> register(RegisterCredentials credentials) async {
    try {
      final body = <String, dynamic>{
        'password': credentials.password,
        'displayName': credentials.displayName,
      };
      if (credentials.email != null) body['email'] = credentials.email;
      if (credentials.phoneNumber != null) body['phoneNumber'] = credentials.phoneNumber;

      final response = await _client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse<UserModel>(response, UserModel.fromMap);
    } catch (e) {
      return AuthResult<UserModel>.failure(AuthException(e.toString(), code: 'network-error'));
    }
  }

  @override
  Future<AuthResult<UserModel>> login(LoginCredentials credentials) async {
    try {
      final body = <String, dynamic>{
        'password': credentials.password,
      };
      if (credentials.email != null) body['email'] = credentials.email;
      if (credentials.phoneNumber != null) body['phoneNumber'] = credentials.phoneNumber;

      final response = await _client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse<UserModel>(response, UserModel.fromMap);
    } catch (e) {
      return AuthResult.failure(AuthException(e.toString(), code: 'network-error'));
    }
  }

  @override
  Future<AuthResult<void>> sendOtp(String contact, AuthMethod method) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/send-otp'),
        headers: _headers,
        body: jsonEncode({'contact': contact, 'method': method.name}),
      );
      return _handleResponse(response);
    } catch (e) {
      return AuthResult.failure(AuthException(e.toString(), code: 'network-error'));
    }
  }

  @override
  Future<AuthResult<bool>> verifyOtp(String contact, String otp, AuthMethod method) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: _headers,
        body: jsonEncode({'contact': contact, 'otp': otp, 'method': method.name}),
      );
      final result = _handleResponse<Map<String, dynamic>>(response, (json) => json);
      return result.fold(
        (data) => AuthResult.success(data['verified'] as bool? ?? false),
        (error) => AuthResult.failure(error),
      );
    } catch (e) {
      return AuthResult.failure(AuthException(e.toString(), code: 'network-error'));
    }
  }

  @override
  Future<AuthResult<void>> resendOtp(String contact, AuthMethod method) async {
    return sendOtp(contact, method);
  }

  @override
  Future<AuthResult<void>> forgotPassword(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: _headers,
        body: jsonEncode({'email': email}),
      );
      return _handleResponse(response);
    } catch (e) {
      return AuthResult.failure(AuthException(e.toString(), code: 'network-error'));
    }
  }

  @override
  Future<AuthResult<void>> resetPassword({required String token, required String newPassword}) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: _headers,
        body: jsonEncode({'token': token, 'newPassword': newPassword}),
      );
      return _handleResponse(response);
    } catch (e) {
      return AuthResult.failure(AuthException(e.toString(), code: 'network-error'));
    }
  }

  @override
  Future<AuthResult<void>> logout() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return AuthResult.failure(AuthException(e.toString(), code: 'network-error'));
    }
  }

  @override
  Future<AuthResult<UserModel?>> getCurrentUser() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      );
      if (response.statusCode == 401) return const AuthResult.success(null);
      return _handleResponse<UserModel?>(response, (json) => UserModel.fromMap(json));
    } catch (e) {
      return AuthResult.failure(AuthException(e.toString(), code: 'network-error'));
    }
  }

  @override
  Future<AuthResult<UserModel>> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      final body = <String, dynamic>{};
      if (displayName != null) body['displayName'] = displayName;
      if (photoUrl != null) body['photoUrl'] = photoUrl;

      final response = await _client.patch(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _handleResponse<UserModel>(response, UserModel.fromMap);
    } catch (e) {
      return AuthResult.failure(AuthException(e.toString(), code: 'network-error'));
    }
  }

  AuthResult<T> _handleResponse<T>(http.Response response, [T Function(Map<String, dynamic>)? fromJson]) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return const AuthResult.success(null) as AuthResult<T>;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (fromJson != null) {
        return AuthResult.success(fromJson(body));
      }
      return const AuthResult.success(null) as AuthResult<T>;
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final message = body['message'] as String? ?? 'Unknown error';
    final code = body['code'] as String?;
    return AuthResult<T>.failure(AuthException(message, code: code));
  }

  void dispose() => _client.close();
}
