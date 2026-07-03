import 'package:dio/dio.dart';

import 'api_backend_kind.dart';
import 'api_backend_router.dart';

/// Her isteği doğru backend base URL'ine yönlendirir.
class BackendRoutingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.extra['_gatewayFallback'] == true) {
      options.baseUrl = ApiBackendRouter.baseUrlFor(ApiBackendKind.gateway);
      options.extra['apiBackend'] = ApiBackendKind.gateway.label;
    } else {
      final kind = ApiBackendRouter.resolve(
        options.path,
        method: options.method,
      );
      options.baseUrl = ApiBackendRouter.baseUrlFor(kind);
      options.extra['apiBackend'] = kind.label;
    }
    handler.next(options);
  }
}
