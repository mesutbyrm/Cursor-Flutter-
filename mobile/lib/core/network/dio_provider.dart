import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import 'api_exception.dart';
import 'api_endpoints.dart';
import 'cookie_jar_provider.dart';
import 'payment_request_interceptor.dart';
import 'token_storage.dart';

bool _isPublicAuthPath(String path) {
  return path == ApiEndpoints.authMobileLogin ||
      path == ApiEndpoints.authMobileRegister ||
      path == ApiEndpoints.authMobileGoogle ||
      path == ApiEndpoints.authMobileTiktok ||
      path == ApiEndpoints.authMobileRefresh ||
      path == ApiEndpoints.authLogin ||
      path == ApiEndpoints.authRegister ||
      path == ApiEndpoints.authGoogle ||
      path == ApiEndpoints.authTiktok ||
      path == ApiEndpoints.authRefresh;
}

String _refreshPath() =>
    Env.useMobileAuth ? ApiEndpoints.authMobileRefresh : ApiEndpoints.authRefresh;

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final cookieJar = ref.watch(cookieJarProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(CookieManager(cookieJar));
  dio.interceptors.add(PaymentRequestInterceptor());

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
        handler.next(options);
      },
      onError: (e, handler) async {
        final refreshPath = _refreshPath();
        final already = e.requestOptions.extra['_authRetry'] == true;
        if (!already &&
            e.response?.statusCode == 401 &&
            e.requestOptions.path != refreshPath) {
          e.requestOptions.extra['_authRetry'] = true;
          final refreshed = await _tryRefresh(dio, tokenStorage, refreshPath);
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

  return dio;
});

Future<bool> _tryRefresh(
  Dio dio,
  TokenStorage storage,
  String refreshPath,
) async {
  final refresh = await storage.readRefresh();
  if (refresh == null || refresh.isEmpty) return false;
  try {
    final res = await dio.post<Map<String, dynamic>>(
      refreshPath,
      data: {'refreshToken': refresh},
    );
    final data = res.data;
    if (data == null) return false;
    final access = _pickToken(data, 'accessToken', 'access_token');
    if (access == null) return false;
    final newRefresh = _pickToken(data, 'refreshToken', 'refresh_token');
    await storage.writeTokens(
      access: access,
      refresh: newRefresh ?? refresh,
    );
    return true;
  } catch (_) {
    await storage.clear();
    return false;
  }
}

String? _pickToken(Map<String, dynamic> m, String a, String b) {
  final v = m[a] ?? m[b];
  return v is String ? v : null;
}

extension DioApi on Dio {
  Future<Response<T>> safeGet<T>(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      return await get<T>(path, queryParameters: query);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Response<T>> safePost<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    try {
      return await post<T>(
        path,
        data: data,
        queryParameters: query,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Response<T>> safeDelete<T>(
    String path, {
    Object? data,
  }) async {
    try {
      return await delete<T>(path, data: data);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<Response<T>> safePatch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
  }) async {
    try {
      return await patch<T>(
        path,
        data: data,
        queryParameters: query,
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }
}

ApiException _mapDio(DioException e) {
  final code = e.response?.statusCode;
  final body = e.response?.data;

  if (e.type == DioExceptionType.connectionError) {
    final raw = (e.message ?? '').toLowerCase();
    if (raw.contains('failed host lookup') || raw.contains('socketexception')) {
      return ApiException(
        'Sunucu adresi çözülemedi veya ağ yok. Wi-Fi/mobil veriyi kontrol edin.',
        statusCode: code,
      );
    }
    return ApiException(
      'Bağlantı kurulamadı. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      statusCode: code,
    );
  }

  if (code == 405) {
    return ApiException(
      'Bu işlem sunucuda desteklenmiyor (405). Uygulamayı güncelleyin veya web sürümünü deneyin.',
      statusCode: code,
    );
  }
  if (code == 404) {
    return ApiException(
      'İstenen kaynak bulunamadı (404).',
      statusCode: code,
    );
  }

  if (e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return ApiException(
      'Sunucu yanıt vermedi (zaman aşımı). Bağlantınızı kontrol edip tekrar deneyin.',
      statusCode: code,
    );
  }
  if (e.type == DioExceptionType.connectionTimeout) {
    return ApiException(
      'Sunucuya bağlanılamadı (zaman aşımı). İnternet bağlantınızı kontrol edin.',
      statusCode: code,
    );
  }

  String msg = e.message ?? 'Ağ hatası';
  if (body is Map) {
    final m = body.cast<String, dynamic>();
    msg = (m['message'] ?? m['error'] ?? m['detail'] ?? msg).toString();
  } else if (body is String && body.isNotEmpty) {
    if (body.startsWith('<!DOCTYPE') || body.startsWith('<html')) {
      msg = 'Sunucu HTML döndürdü (muhtemelen yanlış uç veya oturum yok).';
    } else {
      msg = body;
    }
  }
  return ApiException(msg, statusCode: code);
}
