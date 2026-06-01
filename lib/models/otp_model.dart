import '../core/auth_type.dart';

class OtpModel {
  final String contact;
  final AuthMethod method;
  final String otp;
  final DateTime? expiresAt;
  final bool isVerified;

  const OtpModel({
    required this.contact,
    required this.method,
    required this.otp,
    this.expiresAt,
    this.isVerified = false,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  OtpModel copyWith({bool? isVerified, DateTime? expiresAt}) => OtpModel(
    contact: contact,
    method: method,
    otp: otp,
    expiresAt: expiresAt ?? this.expiresAt,
    isVerified: isVerified ?? this.isVerified,
  );
}
