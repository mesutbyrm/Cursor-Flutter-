import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/gift_battle.dart';

/// Hediye savaşı uçları — `/api/gifts/battles` (games backend).
class GiftBattleRemoteDataSource {
  GiftBattleRemoteDataSource(this._dio);

  final Dio _dio;

  GiftBattle? _parseBattleBody(dynamic body) {
    if (body == null) return null;
    if (body is Map) {
      final m = asJsonMap(body);
      if (m['success'] == true && m['data'] != null) {
        return _parseBattleBody(m['data']);
      }
      if (m['battle'] is Map) {
        return GiftBattle.fromJson(asJsonMap(m['battle']));
      }
      if (m['data'] is Map) {
        return GiftBattle.fromJson(asJsonMap(m['data']));
      }
      if (m.containsKey('id') || m.containsKey('battleId')) {
        return GiftBattle.fromJson(m);
      }
      final list = m['battles'] ?? m['items'];
      if (list is List && list.isNotEmpty) {
        final first = list.firstWhere((e) => e is Map, orElse: () => null);
        if (first is Map) return GiftBattle.fromJson(asJsonMap(first));
      }
    }
    if (body is List && body.isNotEmpty) {
      final first = body.firstWhere((e) => e is Map, orElse: () => null);
      if (first is Map) return GiftBattle.fromJson(asJsonMap(first));
    }
    return null;
  }

  /// Savaş başlat (1/3/5/10 dk). durationSec ∈ {60,180,300,600}.
  Future<GiftBattle?> startBattle({
    required String context,
    required String contextId,
    required int durationSec,
    required List<({String id, String name})> participants,
  }) async {
    final roomId = contextId.trim();
    final participantPayload = [
      for (final p in participants)
        {
          'participantId': p.id,
          'userId': p.id,
          'displayName': p.name,
        },
    ];
    final bodies = <Map<String, dynamic>>[
      {
        'context': context,
        'contextId': roomId,
        'roomId': roomId,
        'voiceRoomId': roomId,
        'durationSec': durationSec,
        'duration': durationSec,
        'participants': participantPayload,
      },
      {
        'action': 'start',
        'context': context,
        'contextId': roomId,
        'roomId': roomId,
        'durationSec': durationSec,
        'participants': participantPayload,
      },
    ];

    Object? lastError;
    for (final data in bodies) {
      try {
        final res = await _dio.safePost<dynamic>(
          ApiEndpoints.giftsBattles,
          data: data,
        );
        final battle = _parseBattleBody(res.data);
        if (battle != null && battle.id.isNotEmpty) return battle;
      } on Object catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) throw lastError!;
    return null;
  }

  /// Bir bağlamdaki aktif savaşı getir (yoksa null).
  Future<GiftBattle?> activeBattle({
    required String context,
    required String contextId,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.giftsBattles,
      query: {
        'context': context,
        'contextId': contextId,
        'roomId': contextId,
        'status': 'active',
      },
    );
    final battle = _parseBattleBody(res.data);
    if (battle != null && battle.isActive) return battle;
    return null;
  }

  /// Savaş durumu (poll).
  Future<GiftBattle?> getBattle(String id) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.giftsBattle(id));
    return _parseBattleBody(res.data);
  }
}
