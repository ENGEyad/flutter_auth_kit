import '../core/auth_result.dart';
import '../models/user_model.dart';

abstract class PhoneAuthService {
  Future<AuthResult<void>> sendPhoneOtp(String phoneNumber);
  Future<AuthResult<bool>> verifyPhoneOtp(String phoneNumber, String otp);
  Future<AuthResult<void>> resendPhoneOtp(String phoneNumber);
  Future<AuthResult<UserModel>> loginWithPhone(String phoneNumber, String password);
  Future<AuthResult<UserModel>> registerWithPhone(String phoneNumber, String password, {String? displayName});
}
