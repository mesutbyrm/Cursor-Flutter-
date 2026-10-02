import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_notification_entity.dart';

/// Cihazda üretilen (sunucuda kaydı olmayan) bildirimlerin uygulama içi kaydı:
/// yayın hatırlatıcıları, yerel ödeme/bilgi bildirimleri vb. Sunucu bildirimleri
/// zaten `/api/notifications` ile gelir; bu liste onlarla birleştirilir.
abstract final class LocalNotificationStore {
  static const _key = 'local_in_app_notifications_v1';
  static const maxItems = 50;
  static const idPrefix = 'local-';

  static bool isLocalId(String id) => id.startsWith(idPrefix);

  static Future<void> record({
    required String title,
    required String body,
    String? type,
    String? targetPath,
    DateTime? now,
  }) async {
    final t = title.trim();
    if (t.isEmpty && body.trim().isEmpty) return;
    final at = now ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final list = _decode(prefs.getString(_key));
    // Aynı başlık+metin 60 sn içinde tekrar gelirse tek kayıt.
    final dup = list.any(
      (m) =>
          m['title'] == t &&
          m['body'] == body &&
          at.difference(
                DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0),
              ).inSeconds.abs() <
              60,
    );
    if (dup) return;
    list.insert(0, {
      'id': '$idPrefix${at.millisecondsSinceEpoch}',
      'title': t,
      'body': body,
      'type': type ?? 'local',
      'targetPath': targetPath,
      'createdAt': at.toIso8601String(),
    });
    if (list.length > maxItems) list.removeRange(maxItems, list.length);
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<List<AppNotificationEntity>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return [
      for (final m in _decode(prefs.getString(_key)))
        AppNotificationEntity(
          id: m['id']?.toString() ?? '',
          title: m['title']?.toString() ?? '',
          body: m['body']?.toString(),
          createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? ''),
          type: m['type']?.toString(),
          targetPath: m['targetPath']?.toString(),
        ),
    ];
  }

  /// Çıkışta kullanıcılar arası sızıntı olmasın.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static List<Map<String, dynamic>> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final d = jsonDecode(raw);
      if (d is List) {
        return [
          for (final e in d)
            if (e is Map) e.map((k, v) => MapEntry(k.toString(), v)),
        ];
      }
    } catch (_) {}
    return [];
  }
}
