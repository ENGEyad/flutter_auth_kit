class EmailValidator {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? validate(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(email.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }
}
