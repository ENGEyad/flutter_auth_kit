# flutter_auth_kit

A Flutter package for managing authentication via email or phone number, including OTP, forgot/reset password, login, and registration.

## Features

- **Email Authentication** — register, login, send/verify email OTP, forgot/reset password
- **Phone Authentication** — register, login, send/verify phone OTP
- **Backend Agnostic** — built-in Firebase and REST API implementations
- **State Management** — ready-to-use `AuthProvider` (ChangeNotifier)
- **Reusable Widgets** — `OtpInputField`, `AuthTextField`, `AuthButton`
- **Validators** — email and phone number validation

## Usage

```dart
import 'package:flutter_auth_kit/flutter_auth_kit.dart';

final auth = AuthProvider(FirebaseAuthService());

// Register
await auth.register(RegisterCredentials.email(
  email: 'user@example.com',
  password: 'pass123',
));

// Login
await auth.login(LoginCredentials(
  identifier: 'user@example.com',
  password: 'pass123',
));

// Send & verify OTP
await auth.sendOtp('+1234567890', AuthMethod.phone);
await auth.verifyOtp('+1234567890', '123456', AuthMethod.phone);

// Forgot & reset password
await auth.forgotPassword('user@example.com');
await auth.resetPassword(token: 'resetToken', newPassword: 'newPass456');
```

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_auth_kit: ^0.1.0
```
