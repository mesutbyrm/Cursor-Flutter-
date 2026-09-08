import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Bana Özel yerel — favoriler, açılan geçmiş, sıralama.
class BanaOzelPreferencesStore {
  BanaOzelPreferencesStore(this._prefs);

  static const _favoritesKey = 'bana_ozel_favorites_v1';
  static const _historyKey = 'bana_ozel_open_history_v1';
  static const _sortKey = 'bana_ozel_sort_v1';

  final SharedPreferences _prefs;

  static Future<BanaOzelPreferencesStore> create() async {
    return BanaOzelPreferencesStore(await SharedPreferences.getInstance());
  }

  BanaOzelSortMode get sortMode {
    final raw = _prefs.getString(_sortKey);
    return BanaOzelSortMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => BanaOzelSortMode.catalog,
    );
  }

  Future<void> setSortMode(BanaOzelSortMode mode) async {
    await _prefs.setString(_sortKey, mode.name);
  }

  Set<String> get favoriteSlugs {
    final raw = _prefs.getStringList(_favoritesKey) ?? const [];
    return raw.toSet();
  }

  Future<void> toggleFavorite(String slug) async {
    final set = favoriteSlugs;
    if (set.contains(slug)) {
      set.remove(slug);
    } else {
      set.add(slug);
    }
    await _prefs.setStringList(_favoritesKey, set.toList());
  }

  List<BanaOzelOpenHistoryEntry> get openHistory {
    final raw = _prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => BanaOzelOpenHistoryEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> recordOpen({
    required String slug,
    required String title,
  }) async {
    final now = DateTime.now().toIso8601String();
    final next = [
      BanaOzelOpenHistoryEntry(slug: slug, title: title, openedAt: now),
      ...openHistory.where((e) => e.slug != slug),
    ].take(20).toList();
    await _prefs.setString(
      _historyKey,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }
}

enum BanaOzelSortMode {
  catalog,
  name,
  priceLow,
  priceHigh,
}

class BanaOzelOpenHistoryEntry {
  const BanaOzelOpenHistoryEntry({
    required this.slug,
    required this.title,
    required this.openedAt,
  });

  factory BanaOzelOpenHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BanaOzelOpenHistoryEntry(
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      openedAt: json['openedAt']?.toString() ?? '',
    );
  }

  final String slug;
  final String title;
  final String openedAt;

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'title': title,
        'openedAt': openedAt,
      };
}
