class UserModel {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  const UserModel({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.createdAt,
    this.metadata,
  });

  UserModel copyWith({
    String? uid,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    if (email != null) 'email': email,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (displayName != null) 'displayName': displayName,
    if (photoUrl != null) 'photoUrl': photoUrl,
    'isEmailVerified': isEmailVerified,
    'isPhoneVerified': isPhoneVerified,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (metadata != null) 'metadata': metadata,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'] as String,
    email: map['email'] as String?,
    phoneNumber: map['phoneNumber'] as String?,
    displayName: map['displayName'] as String?,
    photoUrl: map['photoUrl'] as String?,
    isEmailVerified: (map['isEmailVerified'] as bool?) ?? false,
    isPhoneVerified: (map['isPhoneVerified'] as bool?) ?? false,
    createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
    metadata: map['metadata'] as Map<String, dynamic>?,
  );
}
