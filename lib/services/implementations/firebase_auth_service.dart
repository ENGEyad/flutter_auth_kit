import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/auth_exception.dart';
import '../../core/auth_result.dart';
import '../../core/auth_type.dart';
import '../../models/auth_credentials.dart';
import '../../models/user_model.dart';
import '../auth_service.dart';

class FirebaseAuthService extends AuthService {
  final fb.FirebaseAuth _auth;

  FirebaseAuthService({fb.FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? fb.FirebaseAuth.instance;

  @override
  Future<AuthResult<UserModel>> register(RegisterCredentials credentials) async {
    try {
      fb.UserCredential credential;
      if (credentials.method == AuthMethod.email) {
        credential = await _auth.createUserWithEmailAndPassword(
          email: credentials.email!,
          password: credentials.password,
        );
      } else {
        credential = await _auth.createUserWithEmailAndPassword(
          email: '', // phone registration via Firebase typically uses phone auth provider
          password: credentials.password,
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
        credential = await _auth.signInWithEmailAndPassword(
          email: credentials.email!,
          password: credentials.password,
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
        await _auth.signInWithPhoneNumber(contact);
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
  Future<AuthResult<bool>> verifyOtp(String contact, String otp, AuthMethod method) async {
    try {
      if (method == AuthMethod.phone) {
        final credential = fb.PhoneAuthProvider.credential(
          verificationId: contact,
          smsCode: otp,
        );
        await _auth.signInWithCredential(credential);
        return const AuthResult.success(true);
      }
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
  Future<AuthResult<void>> resetPassword({required String token, required String newPassword}) async {
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
      return AuthResult.success(_mapFirebaseUser(user));
    } on fb.FirebaseAuthException catch (e) {
      return AuthResult.failure(AuthException.fromFirebase(e));
    }
  }

  @override
  Future<AuthResult<UserModel>> updateProfile({String? displayName, String? photoUrl}) async {
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
}
