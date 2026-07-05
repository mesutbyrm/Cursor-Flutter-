import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Yerel gizlenen sohbetler — sunucu uç yoksa listeden kaldırır.
abstract final class HiddenConversationsStore {
  static String _key(String userId) => 'dm_hidden_conv_v1_$userId';

  static Future<Set<String>> read(String userId) async {
    if (userId.isEmpty) return {};
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        return list.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
      }
    } catch (_) {}
    return {};
  }

  static Future<void> hide(String userId, String peerId) async {
    if (userId.isEmpty || peerId.isEmpty) return;
    final set = await read(userId);
    set.add(peerId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(set.toList()));
  }

  static Future<void> unhide(String userId, String peerId) async {
    if (userId.isEmpty || peerId.isEmpty) return;
    final set = await read(userId);
    set.remove(peerId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(set.toList()));
  }
}
