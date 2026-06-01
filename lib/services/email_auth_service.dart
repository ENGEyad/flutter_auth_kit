import '../core/auth_result.dart';
import '../models/user_model.dart';

abstract class EmailAuthService {
  Future<AuthResult<UserModel>> registerWithEmail(String email, String password, {String? displayName});
  Future<AuthResult<UserModel>> loginWithEmail(String email, String password);
  Future<AuthResult<void>> sendEmailOtp(String email);
  Future<AuthResult<bool>> verifyEmailOtp(String email, String otp);
  Future<AuthResult<void>> resendEmailOtp(String email);
  Future<AuthResult<void>> forgotPassword(String email);
  Future<AuthResult<void>> resetPassword(String token, String newPassword);
}
