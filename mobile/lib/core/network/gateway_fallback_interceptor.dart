import 'package:dio/dio.dart';

import 'api_backend_router.dart';

/// Yalnızca 502/503/504 durumunda tek seferlik gateway yedeği.
/// Normal akışta kullanılmaz — doğrudan routing tercih edilir.
class GatewayFallbackInterceptor extends Interceptor {
  GatewayFallbackInterceptor({required Dio Function() dioGetter})
      : _dioGetter = dioGetter;

  final Dio Function() _dioGetter;

  static const _gatewayStatuses = {502, 503, 504};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!ApiBackendRouter.hasGatewayFallback) {
      return handler.next(err);
    }
    if (err.requestOptions.extra['_gatewayFallback'] == true) {
      return handler.next(err);
    }
    final code = err.response?.statusCode;
    if (code == null || !_gatewayStatuses.contains(code)) {
      return handler.next(err);
    }

    final options = err.requestOptions;
    options.extra['_gatewayFallback'] = true;
    try {
      final response = await _dioGetter().fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
