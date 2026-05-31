import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Uzak animasyon / ikon önbelleği — FPS dostu tekrar kullanım.
class GiftCacheService {
  GiftCacheService._();
  static final GiftCacheService instance = GiftCacheService._();

  final _memory = _LruMemoryCache<String, Uint8List>(maxEntries: 24);
  final _fileCache = DefaultCacheManager();

  Future<Uint8List?> getBytes(String url) async {
    if (url.isEmpty) return null;
    final mem = _memory.get(url);
    if (mem != null) return mem;

    try {
      final file = await _fileCache.getSingleFile(url);
      final bytes = await file.readAsBytes();
      _memory.put(url, bytes);
      return bytes;
    } catch (e) {
      debugPrint('GiftCacheService: $url — $e');
      return null;
    }
  }

  void prefetchUrls(Iterable<String> urls) {
    for (final u in urls) {
      if (u.startsWith('http')) {
        unawaited(getBytes(u));
      }
    }
  }

  void clear() => _memory.clear();
}

class _LruMemoryCache<K, V> {
  _LruMemoryCache({required this.maxEntries});

  final int maxEntries;
  final _map = LinkedHashMap<K, V>();

  V? get(K key) {
    final v = _map.remove(key);
    if (v == null) return null;
    _map[key] = v;
    return v;
  }

  void put(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    while (_map.length > maxEntries) {
      _map.remove(_map.keys.first);
    }
  }

  void clear() => _map.clear();
}
