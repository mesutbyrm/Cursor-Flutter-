import 'dart:async';

import 'api_exception.dart';

/// Ağ / auth işlemlerinde sonsuz loading önlenir.
abstract final class LoadingTimeout {
  static Future<T> run<T>(
    Future<T> future, {
    Duration timeout = const Duration(seconds: 15),
    String? message,
  }) {
    return future.timeout(
      timeout,
      onTimeout: () {
        throw ApiException(
          message ?? 'İşlem zaman aşımına uğradı. Bağlantınızı kontrol edin.',
        );
      },
    );
  }
}
