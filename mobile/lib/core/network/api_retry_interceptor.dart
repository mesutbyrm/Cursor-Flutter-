import 'package:dio/dio.dart';

import 'connectivity/connectivity_service.dart';

/// Idempotent GET — bağlantı/timeout hatalarında sınırlı yeniden deneme.
class ApiRetryInterceptor extends Interceptor {
  ApiRetryInterceptor({
    required Dio Function() dioGetter,
    ConnectivityService? connectivity,
  })  : _dioGetter = dioGetter,
        _connectivity = connectivity;

  final Dio Function() _dioGetter;
  final ConnectivityService? _connectivity;

  static const _maxAttempts = 2;
  static const _retryable = {
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
        // GET cache katmanı stale dönebilir; ağ yokken devam.
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
    await Future<void>.delayed(Duration(milliseconds: 400 * attempt));

    try {
      final response = await _dioGetter().fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(RequestOptions options, DioException err) {
    if (options.extra['_authRetry'] == true) return false;
    if (options.method.toUpperCase() != 'GET') return false;
    if (!_retryable.contains(err.type)) return false;
    final code = err.response?.statusCode;
    if (code != null && code >= 400 && code < 500) return false;
    return true;
  }
}
