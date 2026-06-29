import 'package:dio/dio.dart';

import '../performance/app_perf_metrics.dart';

/// HTTP istek süresi — AppPerfMetrics'e yazar.
class ApiTimingInterceptor extends Interceptor {
  static const _startKey = '_perfStartMs';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _record(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _record(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _record(RequestOptions options, int? statusCode) {
    final start = options.extra[_startKey] as int?;
    if (start == null) return;
    final ms = DateTime.now().millisecondsSinceEpoch - start;
    AppPerfMetrics.recordApi(options.path, ms, statusCode: statusCode);
  }
}
