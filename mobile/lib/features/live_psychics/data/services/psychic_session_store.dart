import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/psychic_entity.dart';
import '../../domain/entities/psychic_session_entity.dart';

/// Oturum kalıcılığı — izin / process restore.
abstract final class PsychicSessionStore {
  static const _key = 'live_psychics_active_session_v1';

  static Future<void> save(PsychicSessionEntity session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_toJson(session)));
  }

  static Future<PsychicSessionEntity?> load() async {
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

  static Map<String, dynamic> _toJson(PsychicSessionEntity s) {
    final p = s.psychic;
    return {
      'sessionId': s.sessionId,
      'durationMinutes': s.durationMinutes,
      'totalJeton': s.totalJeton,
      'tellerUserId': s.tellerUserId,
      'clientId': s.clientId,
      'isClient': s.isClient,
      'trtcRoomIdOverride': s.trtcRoomIdOverride,
      'fortuneType': s.fortuneType,
      'psychic': {
        'id': p.id,
        'userId': p.userId,
        'name': p.name,
        'bio': p.bio,
        'avatarUrl': p.avatarUrl,
        'isOnline': p.isOnline,
        'rating': p.rating,
        'reviewCount': p.reviewCount,
        'pricePerMinute': p.pricePerMinute,
        'specialties': p.specialties,
        'category': p.category,
        'applicationStatus': p.applicationStatus,
      },
    };
  }

  static PsychicSessionEntity? _fromJson(Map<String, dynamic> map) {
    final sessionId = map['sessionId']?.toString().trim() ?? '';
    if (sessionId.isEmpty) return null;
    final pMap = map['psychic'];
    if (pMap is! Map) return null;
    final p = Map<String, dynamic>.from(pMap);
    final psychicId = p['id']?.toString().trim() ?? '';
    if (psychicId.isEmpty) return null;
    final specs = p['specialties'];
    return PsychicSessionEntity(
      sessionId: sessionId,
      psychic: PsychicEntity(
        id: psychicId,
        userId: p['userId']?.toString(),
        name: p['name']?.toString() ?? 'Falcı',
        bio: p['bio']?.toString(),
        avatarUrl: p['avatarUrl']?.toString(),
        isOnline: p['isOnline'] == true,
        rating: (p['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (p['reviewCount'] as num?)?.toInt() ?? 0,
        pricePerMinute: (p['pricePerMinute'] as num?)?.toInt() ?? 0,
        specialties: specs is List
            ? specs.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
            : const [],
        category: p['category']?.toString(),
        applicationStatus: p['applicationStatus']?.toString(),
      ),
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 10,
      totalJeton: (map['totalJeton'] as num?)?.toInt() ?? 0,
      tellerUserId: map['tellerUserId']?.toString(),
      clientId: map['clientId']?.toString(),
      isClient: map['isClient'] != false,
      trtcRoomIdOverride: map['trtcRoomIdOverride']?.toString(),
      fortuneType: map['fortuneType']?.toString() ?? 'general',
    );
  }
}
