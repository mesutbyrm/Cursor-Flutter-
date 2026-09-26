import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Sunucuda hâlâ açık olabilecek sesli oda presence kayıtları.
///
/// Kayıt, backend join'i onayladığında eklenir ve yalnızca **çıkış sunucu
/// tarafından kabul edildiğinde** silinir. Uygulama öldürüldüğünde,
/// ağ koptuğunda ya da oda değiştirirken çıkış isteği düşerse kayıt burada
/// kalır; bir sonraki açılışta temizlik muhafızı hepsini tek tek düşürür.
///
/// Birden çok oda tutulur: A odasından çıkış başarısızken B odasına girilirse
/// tek slotlu eski yapı A'yı unutuyordu ve kullanıcı iki odada birden
/// görünmeye devam ediyordu.
class VoiceRoomPresenceRecord {
  const VoiceRoomPresenceRecord({
    required this.roomId,
    this.alternate,
    this.userId,
  });

  final String roomId;
  final String? alternate;
  final String? userId;

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        if (alternate != null && alternate!.isNotEmpty) 'alt': alternate,
        if (userId != null && userId!.isNotEmpty) 'userId': userId,
      };

  static VoiceRoomPresenceRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['roomId']?.toString().trim() ?? '';
    if (id.isEmpty) return null;
    final alt = raw['alt']?.toString().trim();
    final uid = raw['userId']?.toString().trim();
    return VoiceRoomPresenceRecord(
      roomId: id,
      alternate: alt != null && alt.isNotEmpty ? alt : null,
      userId: uid != null && uid.isNotEmpty ? uid : null,
    );
  }
}

abstract final class VoiceRoomPresencePersistence {
  static const _listKey = 'voice_presence_pending_rooms';

  // Tek slotlu eski biçim — ilk okumada yeni listeye taşınır.
  static const _legacyRoomKey = 'voice_presence_room_id';
  static const _legacyAltKey = 'voice_presence_room_alt';
  static const _legacyUserKey = 'voice_presence_user_id';

  /// Aynı anda en fazla kaç oda takip edilir (sınırsız büyümeyi önler).
  static const maxRecords = 5;

  static Future<void> recordJoin({
    required String roomId,
    String? alternateRoomId,
    String? userId,
  }) async {
    final id = roomId.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final records = await _read(prefs);
    records.removeWhere((r) => r.roomId == id);
    records.add(
      VoiceRoomPresenceRecord(
        roomId: id,
        alternate: alternateRoomId?.trim(),
        userId: userId?.trim(),
      ),
    );
    while (records.length > maxRecords) {
      records.removeAt(0);
    }
    await _write(prefs, records);
  }

  /// Çıkışı sunucu kabul etti — bu oda artık takip edilmez.
  static Future<void> clearRoom(String roomId) async {
    final id = roomId.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final records = await _read(prefs);
    final before = records.length;
    records.removeWhere(
      (r) => r.roomId == id || (r.alternate != null && r.alternate == id),
    );
    if (records.length == before) return;
    await _write(prefs, records);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_listKey);
    await prefs.remove(_legacyRoomKey);
    await prefs.remove(_legacyAltKey);
    await prefs.remove(_legacyUserKey);
  }

  /// Sunucuda açık kalmış olabilecek tüm kayıtlar (en eski önce).
  static Future<List<VoiceRoomPresenceRecord>> readPendingAll() async {
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs);
  }

  /// En son kaydedilen oda — geriye dönük uyumluluk için.
  static Future<VoiceRoomPresenceRecord?> readPending() async {
    final records = await readPendingAll();
    return records.isEmpty ? null : records.last;
  }

  static Future<List<VoiceRoomPresenceRecord>> _read(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_listKey);
    final records = <VoiceRoomPresenceRecord>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            final record = VoiceRoomPresenceRecord.fromJson(item);
            if (record != null) records.add(record);
          }
        }
      } catch (_) {
        // Bozuk kayıt: yok say, aşağıdaki legacy taşıma devreye girer.
      }
    }

    final legacyId = prefs.getString(_legacyRoomKey)?.trim() ?? '';
    if (legacyId.isNotEmpty) {
      final alt = prefs.getString(_legacyAltKey)?.trim();
      final uid = prefs.getString(_legacyUserKey)?.trim();
      if (!records.any((r) => r.roomId == legacyId)) {
        records.add(
          VoiceRoomPresenceRecord(
            roomId: legacyId,
            alternate: alt != null && alt.isNotEmpty ? alt : null,
            userId: uid != null && uid.isNotEmpty ? uid : null,
          ),
        );
      }
      await prefs.remove(_legacyRoomKey);
      await prefs.remove(_legacyAltKey);
      await prefs.remove(_legacyUserKey);
      await _write(prefs, records);
    }
    return records;
  }

  static Future<void> _write(
    SharedPreferences prefs,
    List<VoiceRoomPresenceRecord> records,
  ) async {
    if (records.isEmpty) {
      await prefs.remove(_listKey);
      return;
    }
    await prefs.setString(
      _listKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }
}
