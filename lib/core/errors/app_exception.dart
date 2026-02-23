class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() {
    if (code == null) {
      return 'AppException(message: $message, cause: $cause)';
    }
    return 'AppException(code: $code, message: $message, cause: $cause)';
  }
}