class PhoneValidator {
  static final RegExp _phoneRegex = RegExp(r'^\+?[1-9]\d{6,14}$');

  static String? validate(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!_phoneRegex.hasMatch(phone.trim())) {
      return 'Enter a valid phone number (e.g. +1234567890)';
    }
    return null;
  }
}
