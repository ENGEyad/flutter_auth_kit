import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/auth_exception.dart';
import '../../core/auth_result.dart';
import '../../core/auth_type.dart';
import '../../models/auth_credentials.dart';
import '../../models/user_model.dart';
import '../auth_service.dart';

class FirebaseAuthService extends AuthService {
  static const Duration otpSessionTtl = Duration(minutes: 10);

  final fb.FirebaseAuth _auth;
  _PhoneVerificationSession? _phoneVerificationSession;

  FirebaseAuthService({fb.FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? fb.FirebaseAuth.instance;

  @override
  Future<AuthResult<UserModel>> register(
    RegisterCredentials credentials,
  ) async {
    try {
      fb.UserCredential credential;
      if (credentials.method == AuthMethod.email) {
        credential = await _auth.createUserWithEmailAndPassword(
          email: credentials.email!,
          password: credentials.password,
        );
      } else {
        return const AuthResult.failure(
          AuthException(
            'Firebase phone registration requires OTP verification. Use sendOtp and verifyOtp.',
            code: 'unsupported-auth-method',
          ),
        );
      }
      return AuthResult.success(_mapFirebaseUser(credential.user!));
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(AuthException.fromFirebase(e));
    }
  }

  @override
  Future<AuthResult<UserModel>> login(LoginCredentials credentials) async {
    try {
      fb.UserCredential credential;
      if (credentials.method == AuthMethod.email) {
        credential = await _auth.signInWithEmailAndPassword(
          email: credentials.email!,
          password: credentials.password,
        );
      } else {
        return const AuthResult.failure(
          AuthException(
            'Firebase phone login requires OTP verification. Use sendOtp and verifyOtp.',
            code: 'unsupported-auth-method',
          ),
        );
      }
      return AuthResult.success(_mapFirebaseUser(credential.user!));
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(AuthException.fromFirebase(e));
    }
  }

  @override
  Future<AuthResult<void>> sendOtp(String contact, AuthMethod method) async {
    try {
      if (method == AuthMethod.phone) {
        final result = await _auth.signInWithPhoneNumber(contact);
        _phoneVerificationSession = _PhoneVerificationSession(
          contact: _normalizeContact(contact),
          verificationId: result.verificationId,
          expiresAt: DateTime.now().add(otpSessionTtl),
        );
      } else {
        final user = _auth.currentUser;
        if (user != null) {
          await user.sendEmailVerification();
        }
      }
      return const AuthResult.success(null);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(AuthException.fromFirebase(e));
    }
  }

  @override
  Future<AuthResult<bool>> verifyOtp(
    String contact,
    String otp,
    AuthMethod method,
  ) async {
    try {
      if (method == AuthMethod.phone) {
        final session = _phoneVerificationSession;
        if (session == null || session.isExpired) {
          _phoneVerificationSession = null;
          return const AuthResult.failure(
            AuthException(
              'No verification session found. Please send OTP first.',
              code: 'session-expired',
            ),
          );
        }
        if (session.contact != _normalizeContact(contact)) {
          return const AuthResult.failure(
            AuthException(
              'Verification session does not match this phone number.',
              code: 'verification-contact-mismatch',
            ),
          );
        }
        final credential = fb.PhoneAuthProvider.credential(
          verificationId: session.verificationId,
          smsCode: otp,
        );
        await _auth.signInWithCredential(credential);
        _phoneVerificationSession = null;
        return const AuthResult.success(true);
      }
      if (otp.isEmpty) {
        return const AuthResult.failure(
          AuthException(
            'Verification code cannot be empty',
            code: 'invalid-verification-code',
          ),
        );
      }
      await _auth.applyActionCode(otp);
      return const AuthResult.success(true);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(AuthException.fromFirebase(e));
    }
  }

  @override
  Future<AuthResult<void>> resendOtp(String contact, AuthMethod method) async {
    return sendOtp(contact, method);
  }

  @override
  Future<AuthResult<void>> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const AuthResult.success(null);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(AuthException.fromFirebase(e));
    }
  }

  @override
  Future<AuthResult<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _auth.confirmPasswordReset(code: token, newPassword: newPassword);
      return const AuthResult.success(null);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(AuthException.fromFirebase(e));
    }
  }

  @override
  Future<AuthResult<void>> logout() async {
    try {
      await _auth.signOut();
      return const AuthResult.success(null);
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(AuthException.fromFirebase(e));
    }
  }

  @override
  Future<AuthResult<UserModel?>> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const AuthResult.success(null);
      await user.reload();
      final freshUser = _auth.currentUser;
      if (freshUser == null) return const AuthResult.success(null);
      return AuthResult.success(_mapFirebaseUser(freshUser));
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(AuthException.fromFirebase(e));
    }
  }

  @override
  Future<AuthResult<UserModel>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const AuthResult.failure(AuthException('No authenticated user'));
      }
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);
      await user.reload();
      return AuthResult.success(_mapFirebaseUser(_auth.currentUser!));
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(AuthException.fromFirebase(e));
    }
  }

  UserModel _mapFirebaseUser(fb.User user) => UserModel(
    uid: user.uid,
    email: user.email,
    phoneNumber: user.phoneNumber,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    isEmailVerified: user.emailVerified,
    createdAt: user.metadata.creationTime,
  );

  String _normalizeContact(String contact) => contact.trim();
}

class _PhoneVerificationSession {
  final String contact;
  final String verificationId;
  final DateTime expiresAt;

  const _PhoneVerificationSession({
    required this.contact,
    required this.verificationId,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
