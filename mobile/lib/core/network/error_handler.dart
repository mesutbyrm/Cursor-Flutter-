import 'api_exception.dart';

/// Merkezi API hata mesajı — UI katmanı `ApiException` yerine bunu kullanır.
abstract final class ErrorHandler {
  static String message(Object error, {String fallback = 'Bir hata oluştu'}) {
    if (error is ApiException) return error.message;
    final raw = ApiException.userMessage(error);
    if (raw.startsWith('ApiException') || raw.isEmpty) return fallback;
    return raw;
  }

  static bool isAuthError(Object error) {
    if (error is ApiException) {
      return error.statusCode == 401 || error.statusCode == 403;
    }
    final s = error.toString().toLowerCase();
    return s.contains('401') || s.contains('unauthorized');
  }

  static bool isNotFound(Object error) {
    return error is ApiException && error.statusCode == 404;
  }
}
