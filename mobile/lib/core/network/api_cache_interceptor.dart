import 'dart:async';

import 'package:dio/dio.dart';

import 'api_cache_policy.dart';
import 'api_http_cache.dart';

/// GET yanıtları — bellek + disk TTL cache ve eşzamanlı istek dedupe.
class ApiCacheInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!ApiCachePolicy.isCacheable(options)) {
      return handler.next(options);
    }

    final key = ApiHttpCache.cacheKey(options);
    final ttl = ApiCachePolicy.ttlFor(options);
    final forceRefresh = options.extra['forceRefresh'] == true;

    if (!forceRefresh) {
      final memory = ApiHttpCache.readMemory(key, ttl);
      if (memory != null) {
        return handler.resolve(ApiHttpCache.toResponse(memory, options));
      }

      final disk = await ApiHttpCache.readDisk(key, ttl);
      if (disk != null) {
        return handler.resolve(ApiHttpCache.toResponse(disk, options));
      }
    }

    final existing = ApiHttpCache.inflightFor(key);
    if (existing != null) {
      try {
        final shared = await existing.future;
        return handler.resolve(
          ApiHttpCache.cloneResponse(shared, options),
        );
      } on DioException catch (e) {
        return handler.reject(e);
      } catch (e) {
        return handler.reject(
          DioException(requestOptions: options, error: e),
        );
      }
    }

    ApiHttpCache.startInflight(key);
    options.extra['_apiCacheKey'] = key;
    options.extra['_apiCacheTtl'] = ttl;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final key = response.requestOptions.extra['_apiCacheKey'] as String?;
    final ttl = response.requestOptions.extra['_apiCacheTtl'] as Duration?;
    if (key != null && ttl != null) {
      unawaited(ApiHttpCache.store(key, response, ttl));
      ApiHttpCache.completeInflight(key, response);
    }
    _invalidateAfterProfileWrite(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final key = err.requestOptions.extra['_apiCacheKey'] as String?;
    if (key != null) {
      final path = ApiCachePolicy.normalizedPath(err.requestOptions.path);
      if (ApiCachePolicy.allowsStaleFallback(path)) {
        final stale = await ApiHttpCache.readStale(key);
        if (stale != null) {
          final response = ApiHttpCache.toResponse(stale, err.requestOptions);
          ApiHttpCache.completeInflight(key, response);
          return handler.resolve(response);
        }
      }
      ApiHttpCache.failInflight(key, err);
    }
    handler.next(err);
  }

  /// Profil yazıldıktan sonra (PATCH /api/me, /api/user/profile …) önbellekte
  /// kalan eski profil yanıtları silinir; yoksa «kaydettim» denip eski
  /// değerler geri geliyordu.
  static void _invalidateAfterProfileWrite(RequestOptions options) {
    if (options.method.toUpperCase() == 'GET') return;
    final path = ApiCachePolicy.normalizedPath(options.path);
    if (path == '/api/me' ||
        path.startsWith('/api/me/') ||
        path.startsWith('/api/user/') ||
        path.startsWith('/api/profile')) {
      unawaited(ApiHttpCache.invalidatePath('/api/me'));
      unawaited(ApiHttpCache.invalidatePath('/api/user'));
    }
  }
}
