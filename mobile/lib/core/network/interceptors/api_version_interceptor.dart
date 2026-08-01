import 'package:dio/dio.dart';

import '../../config/api_config.dart';
import '../api_path_v1.dart';

/// İstek path'lerini `/api/v1/...` formatına yükseltir ([ApiConfig.useApiV1]).
class ApiVersionInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (ApiConfig.useApiV1 && options.path.contains('/api/')) {
      options.path = ApiPathV1.fromLegacy(options.path);
    }
    handler.next(options);
  }
}
