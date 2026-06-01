import '../core/auth_result.dart';
import '../core/auth_type.dart';
import '../models/auth_credentials.dart';
import '../models/user_model.dart';

abstract class AuthService {
  Future<AuthResult<UserModel>> register(RegisterCredentials credentials);
  Future<AuthResult<UserModel>> login(LoginCredentials credentials);
  Future<AuthResult<void>> sendOtp(String contact, AuthMethod method);
  Future<AuthResult<bool>> verifyOtp(String contact, String otp, AuthMethod method);
  Future<AuthResult<void>> resendOtp(String contact, AuthMethod method);
  Future<AuthResult<void>> forgotPassword(String email);
  Future<AuthResult<void>> resetPassword({required String token, required String newPassword});
  Future<AuthResult<void>> logout();
  Future<AuthResult<UserModel?>> getCurrentUser();
  Future<AuthResult<UserModel>> updateProfile({String? displayName, String? photoUrl});
}
