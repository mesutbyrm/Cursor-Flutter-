import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../offline/api_cache_store.dart';
import 'api_cache_policy.dart';

/// Bellek + disk HTTP önbelleği ve eşzamanlı istek tekilleştirme.
abstract final class ApiHttpCache {
  static const _memoryMaxEntries = 256;
  static const _diskPrefix = 'http_v1_';

  static final Map<String, _CacheEntry> _memory = {};
  static final Map<String, Completer<Response<dynamic>>> _inflight = {};

  /// İstek anahtarı — method, path, query, auth parmak izi.
  static String cacheKey(RequestOptions options) {
    final path = ApiCachePolicy.normalizedPath(options.path);
    final query = _canonicalQuery(options.queryParameters);
    final auth = options.headers['Authorization']?.toString() ?? '';
    final authTag =
        auth.isEmpty ? 'public' : auth.hashCode.toRadixString(16);
    return '${options.method.toUpperCase()}|$path|$query|$authTag';
  }

  static String _canonicalQuery(Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return '';
    final keys = query.keys.toList()..sort();
    return keys.map((k) => '$k=${query[k]}').join('&');
  }

  static _CacheEntry? readMemory(String key, Duration ttl) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (!entry.isFresh(ttl)) {
      _memory.remove(key);
      return null;
    }
    _touchMemory(key, entry);
    return entry;
  }

  static Future<_CacheEntry?> readDisk(String key, Duration ttl) async {
    final raw = await ApiCacheStore.readRaw('$_diskPrefix$key', maxAge: ttl);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _CacheEntry.fromJson(map);
    } catch (_) {
      await ApiCacheStore.clearRaw('$_diskPrefix$key');
      return null;
    }
  }

  static Future<_CacheEntry?> readStale(String key) async {
    final mem = _memory[key];
    if (mem != null) return mem;
    final raw = await ApiCacheStore.readRaw(
      '$_diskPrefix$key',
      maxAge: ApiCachePolicy.staleMaxAge,
    );
    if (raw == null) return null;
    try {
      return _CacheEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> store(String key, Response<dynamic> response, Duration ttl) async {
    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      return;
    }
    final entry = _CacheEntry(
      data: response.data,
      statusCode: response.statusCode!,
      savedAt: DateTime.now(),
    );
    _writeMemory(key, entry);
    await ApiCacheStore.writeRaw(
      '$_diskPrefix$key',
      jsonEncode(entry.toJson()),
    );
  }

  static void _writeMemory(String key, _CacheEntry entry) {
    _memory[key] = entry;
    _touchMemory(key, entry);
    while (_memory.length > _memoryMaxEntries) {
      _memory.remove(_memory.keys.first);
    }
  }

  static void _touchMemory(String key, _CacheEntry entry) {
    _memory.remove(key);
    _memory[key] = entry;
  }

  static Completer<Response<dynamic>>? inflightFor(String key) => _inflight[key];

  static Completer<Response<dynamic>> startInflight(String key) {
    final existing = _inflight[key];
    if (existing != null) return existing;
    final c = Completer<Response<dynamic>>();
    _inflight[key] = c;
    return c;
  }

  static void completeInflight(String key, Response<dynamic> response) {
    final c = _inflight.remove(key);
    if (c != null && !c.isCompleted) {
      c.complete(cloneResponse(response, response.requestOptions));
    }
  }

  static void failInflight(String key, DioException error) {
    final c = _inflight.remove(key);
    if (c != null && !c.isCompleted) {
      c.completeError(error);
    }
  }

  static Response<dynamic> toResponse(_CacheEntry entry, RequestOptions options) {
    return Response<dynamic>(
      requestOptions: options,
      data: entry.data,
      statusCode: entry.statusCode,
      statusMessage: 'OK',
    );
  }

  static Response<dynamic> cloneResponse(
    Response<dynamic> source,
    RequestOptions options,
  ) {
    return Response<dynamic>(
      requestOptions: options,
      data: source.data,
      statusCode: source.statusCode,
      statusMessage: source.statusMessage,
      headers: source.headers,
    );
  }

  static Future<void> clearAll() async {
    _memory.clear();
    _inflight.clear();
    await ApiCacheStore.clearByPrefix(_diskPrefix);
  }

  static Future<void> invalidatePath(String pathPrefix) async {
    final norm = ApiCachePolicy.normalizedPath(pathPrefix);
    _memory.removeWhere((k, _) => k.contains('|$norm'));
  }
}

final class _CacheEntry {
  const _CacheEntry({
    required this.data,
    required this.statusCode,
    required this.savedAt,
  });

  final dynamic data;
  final int statusCode;
  final DateTime savedAt;

  bool isFresh(Duration ttl) =>
      DateTime.now().difference(savedAt) <= ttl;

  Map<String, dynamic> toJson() => {
        'data': data,
        'statusCode': statusCode,
        'savedAt': savedAt.toIso8601String(),
      };

  factory _CacheEntry.fromJson(Map<String, dynamic> json) {
    return _CacheEntry(
      data: json['data'],
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 200,
      savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
