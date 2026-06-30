import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Yerel silinen mesaj kimlikleri — sunucu DELETE desteklemese bile UI'dan kaldırır.
abstract final class DeletedMessagesStore {
  static String _key(String userId) => 'dm_deleted_v1_$userId';

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

  static Future<void> add(String userId, String messageId) async {
    if (userId.isEmpty || messageId.isEmpty) return;
    final set = await read(userId);
    set.add(messageId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(set.toList()));
  }
}
