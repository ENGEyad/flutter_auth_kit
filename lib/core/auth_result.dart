import 'auth_exception.dart';

class AuthResult<T> {
  final T? data;
  final AuthException? error;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  const AuthResult.success(this.data) : error = null;
  const AuthResult.failure(this.error) : data = null;

  R fold<R>(R Function(T data) onSuccess, R Function(AuthException error) onFailure) {
    if (isSuccess) {
      return onSuccess(data as T);
    }
    return onFailure(error!);
  }
}
