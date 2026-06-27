import 'package:canlifal_social/core/network/api_cache_policy.dart';
import 'package:canlifal_social/core/network/api_http_cache.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('ApiCachePolicy', () {
    test('GET is cacheable, POST is not', () {
      expect(
        ApiCachePolicy.isCacheable(RequestOptions(path: '/api/me')),
        isTrue,
      );
      expect(
        ApiCachePolicy.isCacheable(
          RequestOptions(path: '/api/me', method: 'POST'),
        ),
        isFalse,
      );
    });

    test('auth and stream paths are never cached', () {
      expect(
        ApiCachePolicy.isCacheable(
          RequestOptions(path: '/api/auth/mobile-login'),
        ),
        isFalse,
      );
      expect(
        ApiCachePolicy.isCacheable(
          RequestOptions(path: '/api/chat/rooms/x/stream'),
        ),
        isFalse,
      );
    });

    test('forceRefresh and noCache bypass cache', () {
      expect(
        ApiCachePolicy.isCacheable(
          RequestOptions(
            path: '/api/me',
            extra: {'forceRefresh': true},
          ),
        ),
        isFalse,
      );
      expect(
        ApiCachePolicy.isCacheable(
          RequestOptions(path: '/api/me', extra: {'noCache': true}),
        ),
        isFalse,
      );
    });

    test('ttl varies by path', () {
      final me = RequestOptions(path: '/api/me');
      final live = RequestOptions(path: '/api/live/streams');
      expect(ApiCachePolicy.ttlFor(me), const Duration(seconds: 45));
      expect(ApiCachePolicy.ttlFor(live), const Duration(seconds: 15));
    });
  });

  group('ApiHttpCache', () {
    test('cacheKey includes method path query and auth', () {
      final a = RequestOptions(
        path: '/api/me',
        method: 'GET',
        headers: {'Authorization': 'Bearer token-a'},
      );
      final b = RequestOptions(
        path: '/api/me',
        method: 'GET',
        headers: {'Authorization': 'Bearer token-b'},
      );
      expect(ApiHttpCache.cacheKey(a), isNot(ApiHttpCache.cacheKey(b)));
    });

    test('memory store and read roundtrip', () async {
      await ApiHttpCache.clearAll();
      const key = 'GET|/api/test||public';
      final entry = Response<dynamic>(
        requestOptions: RequestOptions(path: '/api/test'),
        data: {'ok': true},
        statusCode: 200,
      );
      await ApiHttpCache.store(key, entry, const Duration(minutes: 5));
      final hit = ApiHttpCache.readMemory(key, const Duration(minutes: 5));
      expect(hit, isNotNull);
      expect(hit!.data, {'ok': true});
    });
  });
}
