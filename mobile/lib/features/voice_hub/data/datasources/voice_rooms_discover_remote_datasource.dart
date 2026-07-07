import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../gifts/data/leaderboard_remote_datasource.dart';
import '../../../gifts/domain/gift_leaderboard_entry.dart';
import '../../../live/data/datasources/live_remote_datasource.dart';
import '../../../live/domain/entities/voice_room_entity.dart';

/// Abacus AI / canlifal.com sesli oda keşfet veri kaynağı.
class VoiceRoomsDiscoverRemoteDataSource {
  VoiceRoomsDiscoverRemoteDataSource(
    this._dio,
    this._liveRemote,
    this._leaderboard,
  );

  final Dio _dio;
  final LiveRemoteDataSource _liveRemote;
  final LeaderboardRemoteDataSource _leaderboard;

  Future<List<VoiceRoomEntity>> fetchVoiceRooms({String? categoryId}) async {
    final rooms = await _liveRemote.fetchVoiceRooms();
    if (categoryId == null || categoryId.isEmpty || categoryId == 'all') {
      return rooms;
    }
    return rooms.where((r) => _matchesCategory(r, categoryId)).toList();
  }

  bool _matchesCategory(VoiceRoomEntity room, String categoryId) {
    final hay = '${room.nameTr} ${room.descTr ?? ''} ${room.roomType ?? ''}'
        .toLowerCase();
    return switch (categoryId) {
      'popular' => room.displayOnline >= 50,
      'chat' => true,
      'music' =>
        room.activeDjId != null ||
            room.djUserIds.isNotEmpty ||
            hay.contains('müzik') ||
            hay.contains('dj'),
      'love' => hay.contains('aşk') || hay.contains('flört'),
      'game' => hay.contains('oyun') || hay.contains('game'),
      'night' => hay.contains('gece'),
      _ => true,
    };
  }

  Future<List<Map<String, dynamic>>> fetchTrendTopics() async {
    for (final path in [
      ApiEndpoints.trends,
      ApiEndpoints.shortVideosHashtagsTrending,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final parsed = _parseTrendList(res.data);
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {}
    }
    return const [];
  }

  List<Map<String, dynamic>> _parseTrendList(dynamic body) {
    dynamic list;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      list = pick(data, [
        'trends',
        'topics',
        'hashtags',
        'items',
        'tags',
      ]);
    } else {
      list = body;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<GiftLeaderboardEntry>> fetchActiveSpeakers() =>
      _leaderboard.fetchGlobalGiftLeaderboard(
        period: GiftLeaderboardPeriod.weekly,
        type: 'gifts',
      );
}
