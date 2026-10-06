import 'package:dio/dio.dart';

import '../diagnostics/cf_diagnostic_logger.dart';

/// API isteklerini dosya diagnostic logger'a yazar (JWT loglanmaz).
class CfDiagnosticDioInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (CfDiagnosticLogger.active) {
      final trace = CfDiagnosticLogger.newTraceId();
      options.extra['_cf_diag_trace'] = trace;
      options.extra['_cf_diag_req'] = CfDiagnosticLogger.requestStart(
        method: options.method,
        endpoint: options.path,
        traceId: trace,
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _end(response.requestOptions, statusCode: response.statusCode, success: true);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final timeout = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;
    _end(
      err.requestOptions,
      statusCode: err.response?.statusCode,
      success: false,
      timeout: timeout,
      error: err,
    );
    handler.next(err);
  }

  void _end(
    RequestOptions options, {
    int? statusCode,
    required bool success,
    bool timeout = false,
    Object? error,
  }) {
    if (!CfDiagnosticLogger.active) return;
    final id = options.extra['_cf_diag_req']?.toString();
    if (id == null || id.isEmpty) return;
    CfDiagnosticLogger.requestEnd(
      id,
      statusCode: statusCode,
      success: success,
      timeout: timeout,
      error: error,
    );
  }
}
