/// Flutter Auth Kit
///
/// A comprehensive authentication package that supports email and phone number
/// authentication with OTP, password reset, and profile management.
library;

export 'core/auth_exception.dart';
export 'core/auth_result.dart';
export 'core/auth_type.dart';

export 'models/auth_credentials.dart';
export 'models/otp_model.dart';
export 'models/user_model.dart';

export 'providers/auth_provider.dart';

export 'services/auth_service.dart';
export 'services/email_auth_service.dart';
export 'services/phone_auth_service.dart';

export 'services/implementations/firebase_auth_service.dart';
export 'services/implementations/rest_auth_service.dart';

export 'validators/email_validator.dart';
export 'validators/phone_validator.dart';

export 'widgets/auth_button.dart';
export 'widgets/auth_text_field.dart';
export 'widgets/otp_input_field.dart';
