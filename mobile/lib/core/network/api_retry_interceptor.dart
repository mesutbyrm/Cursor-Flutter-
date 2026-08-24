import 'package:dio/dio.dart';

import 'connectivity/connectivity_service.dart';

/// Idempotent GET — bağlantı/timeout/429/5xx için kılavuz §7 yeniden deneme.
class ApiRetryInterceptor extends Interceptor {
  ApiRetryInterceptor({
    required Dio Function() dioGetter,
    ConnectivityService? connectivity,
  })  : _dioGetter = dioGetter,
        _connectivity = connectivity;

  final Dio Function() _dioGetter;
  final ConnectivityService? _connectivity;

  /// Kılavuz §7: en fazla 3 deneme.
  static const _maxAttempts = 3;
  static const _retryableTypes = {
    DioExceptionType.connectionTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final connectivity = _connectivity;
    if (connectivity != null && !connectivity.isOnline) {
      final isGet = options.method.toUpperCase() == 'GET';
      final forceRefresh = options.extra['forceRefresh'] == true;
      if (isGet && !forceRefresh) {
        return handler.next(options);
      }
      if (!isGet) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'Çevrimdışı — bağlantı bekleniyor',
          ),
        );
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    if (!_shouldRetry(options, err)) {
      return handler.next(err);
    }

    final attempt = (options.extra['_retryAttempt'] as int? ?? 0) + 1;
    if (attempt > _maxAttempts) {
      return handler.next(err);
    }

    options.extra['_retryAttempt'] = attempt;
    await Future<void>.delayed(_backoffFor(err, attempt));

    try {
      final response = await _dioGetter().fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Duration _backoffFor(DioException err, int attempt) {
    final code = err.response?.statusCode;
    if (code == 429) {
      final retryAfter = err.response?.headers.value('retry-after');
      final sec = int.tryParse(retryAfter ?? '');
      if (sec != null && sec > 0) {
        return Duration(seconds: sec.clamp(1, 120));
      }
      return Duration(seconds: 15 * attempt.clamp(1, 4));
    }
    return Duration(milliseconds: 400 * (1 << (attempt - 1)).clamp(1, 8));
  }

  bool _shouldRetry(RequestOptions options, DioException err) {
    if (options.extra['_authRetry'] == true) return false;
    if (options.method.toUpperCase() != 'GET') return false;

    final code = err.response?.statusCode;
    if (code == 429) return true;
    if (code != null && code >= 500) return true;
    if (!_retryableTypes.contains(err.type)) return false;
    if (code != null && code >= 400 && code < 500) return false;
    return true;
  }
}
