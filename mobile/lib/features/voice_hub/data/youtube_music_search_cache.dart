import '../domain/entities/music_queue_item.dart';

/// Kısa ömürlü YouTube arama önbelleği — aynı sorguda tekrar API çağrısını önler.
final class YoutubeMusicSearchCache {
  YoutubeMusicSearchCache({this.ttl = const Duration(minutes: 5)});

  final Duration ttl;
  final _entries = <String, _CacheEntry>{};

  List<YoutubeSearchHit>? get(String query) {
    final key = query.trim().toLowerCase();
    if (key.length < 2) return null;
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.at) > ttl) {
      _entries.remove(key);
      return null;
    }
    return entry.hits;
  }

  void put(String query, List<YoutubeSearchHit> hits) {
    final key = query.trim().toLowerCase();
    if (key.length < 2 || hits.isEmpty) return;
    _entries[key] = _CacheEntry(hits, DateTime.now());
    if (_entries.length > 48) {
      final oldest = _entries.entries.reduce(
        (a, b) => a.value.at.isBefore(b.value.at) ? a : b,
      );
      _entries.remove(oldest.key);
    }
  }

  void clear() => _entries.clear();
}

class _CacheEntry {
  _CacheEntry(this.hits, this.at);
  final List<YoutubeSearchHit> hits;
  final DateTime at;
}
