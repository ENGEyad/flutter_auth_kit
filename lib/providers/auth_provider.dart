import 'package:flutter/foundation.dart';

import '../core/auth_exception.dart';
import '../core/auth_type.dart';
import '../models/auth_credentials.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  UserModel? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  AuthException? _error;
  bool _isLoading = false;

  AuthProvider(this._authService);

  UserModel? get user => _user;
  AuthStatus get status => _status;
  AuthException? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(AuthException? e) {
    _error = e;
    notifyListeners();
  }

  Future<void> initialize() async {
    _setLoading(true);
    _status = AuthStatus.loading;
    final result = await _authService.getCurrentUser();
    result.fold(
      (user) {
        _user = user;
        _status = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      },
      (error) {
        _error = error;
        _status = AuthStatus.unauthenticated;
      },
    );
    _setLoading(false);
  }

  Future<bool> register(RegisterCredentials credentials) async {
    _setLoading(true);
    _setError(null);
    final result = await _authService.register(credentials);
    return result.fold(
      (user) {
        _user = user;
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      },
      (error) {
        _setError(error);
        _setLoading(false);
        return false;
      },
    );
  }

  Future<bool> login(LoginCredentials credentials) async {
    _setLoading(true);
    _setError(null);
    final result = await _authService.login(credentials);
    return result.fold(
      (user) {
        _user = user;
        _status = AuthStatus.authenticated;
        _setLoading(false);
        return true;
      },
      (error) {
        _setError(error);
        _setLoading(false);
        return false;
      },
    );
  }

  Future<bool> sendOtp(String contact, AuthMethod method) async {
    _setLoading(true);
    _setError(null);
    final result = await _authService.sendOtp(contact, method);
    return result.fold(
      (_) {
        _setLoading(false);
        return true;
      },
      (error) {
        _setError(error);
        _setLoading(false);
        return false;
      },
    );
  }

  Future<bool> verifyOtp(String contact, String otp, AuthMethod method) async {
    _setLoading(true);
    _setError(null);
    final result = await _authService.verifyOtp(contact, otp, method);
    return result.fold(
      (verified) {
        _setLoading(false);
        return verified;
      },
      (error) {
        _setError(error);
        _setLoading(false);
        return false;
      },
    );
  }

  Future<bool> resendOtp(String contact, AuthMethod method) async {
    _setLoading(true);
    _setError(null);
    final result = await _authService.resendOtp(contact, method);
    return result.fold(
      (_) {
        _setLoading(false);
        return true;
      },
      (error) {
        _setError(error);
        _setLoading(false);
        return false;
      },
    );
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _setError(null);
    final result = await _authService.forgotPassword(email);
    return result.fold(
      (_) {
        _setLoading(false);
        return true;
      },
      (error) {
        _setError(error);
        _setLoading(false);
        return false;
      },
    );
  }

  Future<bool> resetPassword({required String token, required String newPassword}) async {
    _setLoading(true);
    _setError(null);
    final result = await _authService.resetPassword(token: token, newPassword: newPassword);
    return result.fold(
      (_) {
        _setLoading(false);
        return true;
      },
      (error) {
        _setError(error);
        _setLoading(false);
        return false;
      },
    );
  }

  Future<bool> logout() async {
    _setLoading(true);
    final result = await _authService.logout();
    return result.fold(
      (_) {
        _user = null;
        _status = AuthStatus.unauthenticated;
        _setLoading(false);
        return true;
      },
      (error) {
        _setError(error);
        _setLoading(false);
        return false;
      },
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
