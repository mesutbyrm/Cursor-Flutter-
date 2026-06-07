import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Son şarkı aramaları (cihazda).
class VoiceMusicRecentStore {
  static const _key = 'voice_music_recent_searches_v1';
  static const _max = 12;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).take(_max).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    final next = [q, ...current.where((e) => e.toLowerCase() != q.toLowerCase())]
        .take(_max)
        .toList();
    await prefs.setString(_key, jsonEncode(next));
  }
}
