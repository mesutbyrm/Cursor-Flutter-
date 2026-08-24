/// Merkezi HTTP istemci katmanı — tek giriş noktası.
///
/// **Kullanım**
/// ```dart
/// final dio = ref.watch(dioProvider);
/// final res = await dio.safeGet<Map>(ApiEndpoints.me);
/// final parsed = parseResponse(res, (j) => UserDto.fromJson(j));
/// ```
///
/// **Katmanlar** ([dio_provider.dart]):
/// - [ApiVersionInterceptor] — `/api/v1` öneki
/// - Auth Bearer + 401 refresh ([TokenStorage] + [AuthTokenRefreshCoordinator])
/// - [ApiRetryInterceptor] — 429/5xx exponential backoff
/// - [ApiCacheInterceptor] — GET önbellek (Cache-Control / ETag)
/// - SSE gerçek zamanlı — polling değil ([BaseSseService])
///
/// **Modeller:** [ApiResponse], [ApiError], [Pagination] — [api_response.dart]
/// **Hata kodları:** [ApiErrorCode] — [models/api_error_code.dart]
/// **Yapılandırma:** [ApiConfig] — [config/api_config.dart]
library;

export '../api_response.dart';
export '../config/api_config.dart';
export 'api_exception.dart';
export 'api_path_v1.dart';
export 'dio_provider.dart';
export 'models/api_error_code.dart';
export 'token_storage.dart';
