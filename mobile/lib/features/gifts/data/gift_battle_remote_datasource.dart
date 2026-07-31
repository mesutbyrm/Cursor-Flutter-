import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/gift_battle.dart';

/// Hediye savaşı uçları — `/api/gifts/battles`.
class GiftBattleRemoteDataSource {
  GiftBattleRemoteDataSource(this._dio);

  final Dio _dio;

  /// Savaş başlat (1/3/5/10 dk). durationSec ∈ {60,180,300,600}.
  Future<GiftBattle?> startBattle({
    required String context,
    required String contextId,
    required int durationSec,
    required List<({String id, String name})> participants,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.giftsBattles,
      data: {
        'context': context,
        'contextId': contextId,
        'durationSec': durationSec,
        'participants': [
          for (final p in participants)
            {'participantId': p.id, 'displayName': p.name},
        ],
      },
    );
    final body = res.data;
    if (body is Map) {
      final m = asJsonMap(body);
      final data = m['battle'] is Map ? asJsonMap(m['battle']) : m;
      return GiftBattle.fromJson(data);
    }
    return null;
  }

  /// Bir bağlamdaki aktif savaşı getir (yoksa null).
  Future<GiftBattle?> activeBattle({
    required String context,
    required String contextId,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.giftsBattles,
      query: {'context': context, 'contextId': contextId, 'status': 'active'},
    );
    final body = res.data;
    dynamic list = body;
    if (body is Map) list = asJsonMap(body)['battles'] ?? asJsonMap(body)['data'];
    if (list is! List || list.isEmpty) return null;
    final first = list.firstWhere((e) => e is Map, orElse: () => null);
    if (first is! Map) return null;
    final b = GiftBattle.fromJson(asJsonMap(first));
    return b.isActive ? b : null;
  }

  /// Savaş durumu (poll).
  Future<GiftBattle?> getBattle(String id) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.giftsBattle(id));
    final body = res.data;
    if (body is Map) {
      final m = asJsonMap(body);
      final data = m['battle'] is Map ? asJsonMap(m['battle']) : m;
      return GiftBattle.fromJson(data);
    }
    return null;
  }
}
