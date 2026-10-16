import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// İzleme geçmişi kaydı — sosyal akışta ekrana gelen her paylaşım / video.
///
/// Kısa videolar sunucuda da tutulur (`/api/short-videos/viewed/me`); fotoğraf,
/// yazı, fal ve video gönderileri için sunucuda geçmiş tablosu olmadığından
/// cihazda saklanır (son [maxItems] kayıt).
class WatchHistoryEntry {
  const WatchHistoryEntry({
    required this.key,
    required this.route,
    required this.kind,
    required this.at,
    this.thumbUrl,
    this.title,
  });

  /// `post:<id>` veya `short:<id>`.
  final String key;
  final String route;

  /// video | image | text | fortune
  final String kind;
  final DateTime at;
  final String? thumbUrl;
  final String? title;

  Map<String, dynamic> toJson() => {
        'key': key,
        'route': route,
        'kind': kind,
        'at': at.toIso8601String(),
        if (thumbUrl != null) 'thumb': thumbUrl,
        if (title != null) 'title': title,
      };

  static WatchHistoryEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final key = raw['key']?.toString() ?? '';
    final route = raw['route']?.toString() ?? '';
    if (key.isEmpty || route.isEmpty) return null;
    return WatchHistoryEntry(
      key: key,
      route: route,
      kind: raw['kind']?.toString() ?? 'image',
      at: DateTime.tryParse(raw['at']?.toString() ?? '') ?? DateTime.now(),
      thumbUrl: raw['thumb']?.toString(),
      title: raw['title']?.toString(),
    );
  }
}

class WatchHistoryStore {
  WatchHistoryStore._();

  static const _prefsKey = 'social_watch_history_v1';
  static const maxItems = 150;

  static Future<List<WatchHistoryEntry>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list.map(WatchHistoryEntry.fromJson).whereType<WatchHistoryEntry>().toList();
    } catch (_) {
      return const [];
    }
  }

  /// Kaydı en üste ekler (aynı içerik tekrar izlenirse yukarı taşınır).
  static Future<void> add(WatchHistoryEntry e) async {
    try {
      final current = await load();
      final next = <WatchHistoryEntry>[
        e,
        ...current.where((x) => x.key != e.key),
      ].take(maxItems).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode(next.map((x) => x.toJson()).toList()),
      );
    } catch (_) {}
  }
}

final watchHistoryProvider = FutureProvider.autoDispose<List<WatchHistoryEntry>>(
  (ref) => WatchHistoryStore.load(),
);
