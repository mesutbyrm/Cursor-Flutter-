import 'package:shared_preferences/shared_preferences.dart';

/// Son backend onaylı sesli oda presence kaydı — uygulama yeniden açılışında hayalet üyeliği temizlemek için.
abstract final class VoiceRoomPresencePersistence {
  static const _roomKey = 'voice_presence_room_id';
  static const _altKey = 'voice_presence_room_alt';
  static const _userKey = 'voice_presence_user_id';

  static Future<void> recordJoin({
    required String roomId,
    String? alternateRoomId,
    String? userId,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roomKey, id);
    final alt = alternateRoomId?.trim() ?? '';
    if (alt.isNotEmpty) {
      await prefs.setString(_altKey, alt);
    } else {
      await prefs.remove(_altKey);
    }
    final uid = userId?.trim() ?? '';
    if (uid.isNotEmpty) {
      await prefs.setString(_userKey, uid);
    } else {
      await prefs.remove(_userKey);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roomKey);
    await prefs.remove(_altKey);
    await prefs.remove(_userKey);
  }

  static Future<({String roomId, String? alternate, String? userId})?>
      readPending() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_roomKey)?.trim() ?? '';
    if (id.isEmpty) return null;
    final alt = prefs.getString(_altKey)?.trim();
    final uid = prefs.getString(_userKey)?.trim();
    return (
      roomId: id,
      alternate: alt != null && alt.isNotEmpty ? alt : null,
      userId: uid != null && uid.isNotEmpty ? uid : null,
    );
  }
}
