import '../core/auth_type.dart';

class LoginCredentials {
  final String identifier;
  final String password;
  final AuthMethod method;

  const LoginCredentials({
    required this.identifier,
    required this.password,
    this.method = AuthMethod.email,
  });

  String? get email => method == AuthMethod.email ? identifier : null;
  String? get phoneNumber => method == AuthMethod.phone ? identifier : null;
}

class RegisterCredentials {
  final String? email;
  final String? phoneNumber;
  final String password;
  final String? displayName;
  final AuthMethod method;

  const RegisterCredentials.email({
    required this.email,
    required this.password,
    this.displayName,
  }) : phoneNumber = null,
       method = AuthMethod.email;

  const RegisterCredentials.phone({
    required this.phoneNumber,
    required this.password,
    this.displayName,
  }) : email = null,
       method = AuthMethod.phone;
}
