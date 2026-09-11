import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Şifre isteği red sonrası gece 00:00'a kadar tekrar gönderilmez (yerel).
class RoomPasswordAccessCooldown {
  static String _key(String roomId, String userId) =>
      'room_pwd_req_${roomId}_$userId';

  static Future<bool> canRequest(String roomId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(roomId, userId));
    if (raw == null || raw.isEmpty) return true;
    final until = DateTime.tryParse(raw);
    if (until == null) return true;
    return DateTime.now().isAfter(until);
  }

  static Future<void> markRejectedUntilMidnight(
    String roomId,
    String userId,
  ) async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(roomId, userId), midnight.toIso8601String());
  }

  static Future<void> clear(String roomId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(roomId, userId));
  }
}

final roomPasswordAccessCooldownProvider = Provider<RoomPasswordAccessCooldown>(
  (ref) => RoomPasswordAccessCooldown(),
);
