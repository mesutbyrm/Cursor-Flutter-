class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Snackbar / dialog metni; `ApiException(null): ...` gibi ham `toString` kullanmayın.
  static String userMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }

  @override
  String toString() {
    if (statusCode != null) return 'ApiException($statusCode): $message';
    return 'ApiException: $message';
  }
}
