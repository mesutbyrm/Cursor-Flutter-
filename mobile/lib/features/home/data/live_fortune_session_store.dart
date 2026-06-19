import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/live_fortune_session_entity.dart';
import '../domain/entities/live_fortune_teller_entity.dart';

/// Canlı fal oturumu — izin diyaloğu / process restore sonrası rota `extra` kaybını önler.
abstract final class LiveFortuneSessionStore {
  static const _key = 'live_fortune_active_session_v1';

  static Future<void> save(LiveFortuneSessionEntity session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_toJson(session)));
  }

  static Future<LiveFortuneSessionEntity?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      return _fromJson(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Map<String, dynamic> _toJson(LiveFortuneSessionEntity session) {
    final teller = session.teller;
    return {
      'sessionId': session.sessionId,
      'durationMinutes': session.durationMinutes,
      'totalJeton': session.totalJeton,
      'tellerUserId': session.tellerUserId,
      'clientId': session.clientId,
      'isClient': session.isClient,
      'trtcRoomIdOverride': session.trtcRoomIdOverride,
      'teller': {
        'id': teller.id,
        'userId': teller.userId,
        'name': teller.name,
        'bio': teller.bio,
        'avatarUrl': teller.avatarUrl,
        'isOnline': teller.isOnline,
        'rating': teller.rating,
        'reviewCount': teller.reviewCount,
        'pricePerMinute': teller.pricePerMinute,
        'level': teller.level,
        'specialties': teller.specialties,
        'category': teller.category,
        'applicationStatus': teller.applicationStatus,
        'totalSessions': teller.totalSessions,
        'totalEarnings': teller.totalEarnings,
      },
    };
  }

  static LiveFortuneSessionEntity? _fromJson(Map<String, dynamic> map) {
    final sessionId = map['sessionId']?.toString().trim() ?? '';
    if (sessionId.isEmpty) return null;
    final tellerMap = map['teller'];
    if (tellerMap is! Map) return null;
    final t = Map<String, dynamic>.from(tellerMap);
    final tellerId = t['id']?.toString().trim() ?? '';
    if (tellerId.isEmpty) return null;
    final specs = t['specialties'];
    return LiveFortuneSessionEntity(
      sessionId: sessionId,
      teller: LiveFortuneTellerEntity(
        id: tellerId,
        userId: t['userId']?.toString(),
        name: t['name']?.toString() ?? 'Falcı',
        bio: t['bio']?.toString(),
        avatarUrl: t['avatarUrl']?.toString(),
        isOnline: t['isOnline'] == true,
        rating: (t['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (t['reviewCount'] as num?)?.toInt() ?? 0,
        pricePerMinute: (t['pricePerMinute'] as num?)?.toInt() ?? 0,
        level: t['level']?.toString(),
        specialties: specs is List
            ? specs.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
            : const [],
        category: t['category']?.toString(),
        applicationStatus: t['applicationStatus']?.toString(),
        totalSessions: (t['totalSessions'] as num?)?.toInt() ?? 0,
        totalEarnings: (t['totalEarnings'] as num?)?.toInt() ?? 0,
      ),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 10,
      totalJeton: (map['totalJeton'] as num?)?.toInt() ?? 0,
      tellerUserId: map['tellerUserId']?.toString(),
      clientId: map['clientId']?.toString(),
      isClient: map['isClient'] != false,
      trtcRoomIdOverride: map['trtcRoomIdOverride']?.toString(),
    );
  }
}
