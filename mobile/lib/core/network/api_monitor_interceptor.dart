import 'package:dio/dio.dart';

import 'api_backend_kind.dart';
import 'api_monitor.dart';

/// Debug modunda istek/yanıt metriklerini [ApiMonitor]'a yazar.
class ApiMonitorInterceptor extends Interceptor {
  static const _startKey = '_apiMonitorStartMs';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  void _finish(RequestOptions options, {int? statusCode, String? error}) {
    final start = options.extra[_startKey] as int?;
    if (start == null) return;
    final ms = DateTime.now().millisecondsSinceEpoch - start;
    final backendLabel =
        options.extra['apiBackend']?.toString() ?? ApiBackendKind.main.label;
    final backend = ApiBackendKind.values.firstWhere(
      (k) => k.label == backendLabel,
      orElse: () => ApiBackendKind.main,
    );
    final base = options.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final path = options.path.startsWith('/') ? options.path : '/${options.path}';
    final url = '$base$path';
    final retry = options.extra['_retryAttempt'] as int? ?? 0;

    ApiMonitor.record(
      url: url,
      method: options.method,
      backend: backend,
      statusCode: statusCode,
      responseTimeMs: ms,
      retryCount: retry,
      error: error,
      usedGatewayFallback: options.extra['_gatewayFallback'] == true,
    );
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _finish(response.requestOptions, statusCode: response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _finish(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      error: err.message,
    );
    handler.next(err);
  }
}
