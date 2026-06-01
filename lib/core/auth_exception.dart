class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException($code): $message';

  static AuthException fromFirebase(Exception e) {
    final msg = e.toString();
    if (msg.contains('user-not-found')) {
      return const AuthException('No user found with this credentials', code: 'user-not-found');
    }
    if (msg.contains('wrong-password')) {
      return const AuthException('Wrong password provided', code: 'wrong-password');
    }
    if (msg.contains('email-already-in-use')) {
      return const AuthException('Email is already registered', code: 'email-already-in-use');
    }
    if (msg.contains('invalid-email')) {
      return const AuthException('Invalid email format', code: 'invalid-email');
    }
    if (msg.contains('weak-password')) {
      return const AuthException('Password is too weak', code: 'weak-password');
    }
    if (msg.contains('too-many-requests')) {
      return const AuthException('Too many requests. Try again later.', code: 'too-many-requests');
    }
    if (msg.contains('invalid-verification-code')) {
      return const AuthException('Invalid OTP code', code: 'invalid-verification-code');
    }
    if (msg.contains('session-expired')) {
      return const AuthException('Session expired. Request a new OTP.', code: 'session-expired');
    }
    return AuthException('Authentication failed: ${e.toString()}', code: 'unknown');
  }
}
