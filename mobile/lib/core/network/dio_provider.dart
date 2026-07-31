import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'auth_token_refresh_coordinator.dart';
import '../performance/json_isolate_perf.dart';
import 'api.dart';
import 'api_exception.dart';
import 'api_endpoints.dart';
import 'api_monitor_interceptor.dart';
import 'backend_routing_interceptor.dart';
import 'device_headers.dart';
import 'api_cache_interceptor.dart';
import 'api_retry_interceptor.dart';
import 'api_timing_interceptor.dart';
import 'connectivity/connectivity_service.dart';
import 'cookie_jar_provider.dart';
import 'gateway_fallback_interceptor.dart';
import 'payment_request_interceptor.dart';
import 'token_storage.dart';
import 'voice_room_api_log_interceptor.dart';

bool _isPublicAuthPath(String path) {
  return path == ApiEndpoints.authMobileLogin ||
      path == ApiEndpoints.authMobileRegister ||
      path == ApiEndpoints.authMobileGoogle ||
      path == ApiEndpoints.authMobileApple ||
      path == ApiEndpoints.authMobileTiktok ||
      path == ApiEndpoints.authMobileRefresh ||
      path == ApiEndpoints.authMobileSendVerification ||
      path == ApiEndpoints.authMobileVerifyEmail ||
      path == ApiEndpoints.authForgotPassword ||
      path == ApiEndpoints.authResetPassword ||
      path == ApiEndpoints.authLogin ||
      path == ApiEndpoints.authRegister ||
      path == ApiEndpoints.authGoogle ||
      path == ApiEndpoints.authTiktok ||
      path == ApiEndpoints.authRefresh;
}

String _refreshPath() => Env.useMobileAuth
    ? ApiEndpoints.authMobileRefresh
    : ApiEndpoints.authRefresh;

Dio _createApiDio(Ref ref, {required Dio tokenRefreshDio}) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final cookieJar = ref.watch(cookieJarProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Connection': 'keep-alive',
        'Accept-Encoding': 'gzip, deflate',
      },
      persistentConnection: true,
    ),
  );

  dio.transformer = FusedTransformer(
    contentLengthIsolateThreshold: JsonIsolatePerf.largeThreshold,
  );

  // Backend seçimi — her istek doğru origin'e gider.
  dio.interceptors.add(BackendRoutingInterceptor());
  dio.interceptors.add(CookieManager(cookieJar));
  dio.interceptors.add(PaymentRequestInterceptor());
  dio.interceptors.add(VoiceRoomApiLogInterceptor());
  dio.interceptors.add(ApiMonitorInterceptor());
  dio.interceptors.add(ApiTimingInterceptor());

  final connectivity = ref.read(connectivityServiceProvider);
  dio.interceptors.add(
    ApiRetryInterceptor(dioGetter: () => dio, connectivity: connectivity),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final public = _isPublicAuthPath(options.path);
        if (!public) {
          final token = await tokenStorage.readAccess();
          if (token != null &&
              token.isNotEmpty &&
              token != TokenStorage.sessionCookieMarker) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } else {
          options.headers.remove('Authorization');
        }
        for (final entry in Map.from(deviceRequestHeaders()).entries) {
          options.headers[entry.key] = entry.value;
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        final refreshPath = _refreshPath();
        final already = e.requestOptions.extra['_authRetry'] == true;
        if (!already &&
            e.response?.statusCode == 401 &&
            e.requestOptions.path != refreshPath &&
            e.requestOptions.path != ApiEndpoints.authLogout) {
          e.requestOptions.extra['_authRetry'] = true;
          final refreshed =
              await AuthTokenRefreshCoordinator.instance.refreshLegacy(
            refreshDio: tokenRefreshDio,
            storage: tokenStorage,
            refreshPath: refreshPath,
          );
          if (refreshed) {
            final token = await tokenStorage.readAccess();
            if (token != null && token.isNotEmpty) {
              e.requestOptions.headers['Authorization'] = 'Bearer $token';
            }
            final res = await dio.fetch(e.requestOptions);
            return handler.resolve(res);
          }
        }
        handler.next(e);
      },
    ),
  );

  dio.interceptors.add(GatewayFallbackInterceptor(dioGetter: () => dio));
  dio.interceptors.add(ApiCacheInterceptor());

  return dio;
}

/// Tek Dio — path'e göre Main veya Game backend'e yönlendirilir.
final dioProvider = Provider<Dio>((ref) {
  final refreshOnly = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  final dio = _createApiDio(ref, tokenRefreshDio: refreshOnly);
  Api.bind(dio);
  return dio;
});

/// Geriye dönük alias — artık [dioProvider] ile aynı (routing interceptor içinde).
final gamesDioProvider = Provider<Dio>((ref) => ref.watch(dioProvider));

Future<bool> tryRefreshAccessToken(
  Dio dio,
  TokenStorage storage, {
  String? refreshPath,
}) {
  return tryRefreshAccessTokenLegacy(
    dio,
    storage,
    refreshPath: refreshPath ?? _refreshPath(),
  );
}

extension DioApi on Dio {
  Future<Response<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
    bool forceRefresh = false,
    CancelToken? cancelToken,
    Options? options,
  }) async {
    try {
      final extra = <String, dynamic>{
        if (forceRefresh) 'forceRefresh': true,
        ...?options?.extra,
      };
      return await get<T>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
        options: (options ?? Options()).copyWith(
          extra: extra.isEmpty ? options?.extra : extra,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> safePost<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await post<T>(
        path,
        data: data,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> safeDelete<T>(
    String path, {
    Object? data,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await delete<T>(
        path,
        data: data,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> safePatch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await patch<T>(
        path,
        data: data,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Response<T>> safePut<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await put<T>(
        path,
        data: data,
        queryParameters: query,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
