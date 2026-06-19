import 'dart:async';

import 'api_cache_store.dart';

/// Cache-first GET stratejisi — TTL korunur, ağ hatasında stale cache döner.
abstract final class CacheFirstLoader {
  static Future<T> load<T>({
    required String cacheKey,
    required Future<T> Function() fetch,
    required Map<String, dynamic> Function(T value) encode,
    required T Function(Map<String, dynamic> json) decode,
    Duration maxAge = const Duration(minutes: 15),
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await ApiCacheStore.read(cacheKey, decode, maxAge: maxAge);
      if (cached != null) {
        unawaited(_refreshInBackground(
          cacheKey: cacheKey,
          fetch: fetch,
          encode: encode,
        ));
        return cached;
      }
    }

    try {
      final fresh = await fetch();
      await ApiCacheStore.write(cacheKey, encode(fresh));
      return fresh;
    } catch (e) {
      final stale = await ApiCacheStore.read(
        cacheKey,
        decode,
        maxAge: const Duration(days: 7),
      );
      if (stale != null) return stale;
      rethrow;
    }
  }

  static Future<void> _refreshInBackground<T>({
    required String cacheKey,
    required Future<T> Function() fetch,
    required Map<String, dynamic> Function(T value) encode,
  }) async {
    try {
      final fresh = await fetch();
      await ApiCacheStore.write(cacheKey, encode(fresh));
    } catch (_) {}
  }

  static Map<String, dynamic> encodeList(
    List<Map<String, dynamic>> items,
  ) =>
      {'items': items};

  static List<Map<String, dynamic>> decodeListItems(Map<String, dynamic> json) {
    final raw = json['items'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
