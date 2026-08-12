import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../gifts/data/leaderboard_remote_datasource.dart';
import '../../../gifts/domain/gift_leaderboard_entry.dart';
import '../../../live/data/datasources/live_remote_datasource.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../presentation/utils/voice_room_category_catalog.dart';

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
    final serverCategory = _serverCategoryParam(categoryId);
    final rooms = await _liveRemote.fetchVoiceRooms(category: serverCategory);
    if (categoryId == null || categoryId.isEmpty || categoryId == 'all') {
      return rooms;
    }
    return rooms.where((r) => _matchesCategory(r, categoryId)).toList();
  }

  /// Kılavuz §9.3 — `GET /api/chat/rooms?type=voice&category=…`
  static String? serverCategoryForDiscover(String? categoryId) {
    final id = categoryId?.trim().toLowerCase() ?? '';
    if (id.isEmpty || id == 'all' || id == 'popular') return null;
    for (final c in kVoiceRoomAssignableCategories) {
      if (c.id == id) return c.id;
    }
    return null;
  }

  String? _serverCategoryParam(String? categoryId) =>
      serverCategoryForDiscover(categoryId);

  bool _matchesCategory(VoiceRoomEntity room, String categoryId) {
    if (categoryId == 'popular') {
      return room.displayOnline >= 50;
    }
    final cat = room.category?.trim().toLowerCase();
    if (cat != null && cat.isNotEmpty) {
      return cat == categoryId;
    }
    final hay = '${room.nameTr} ${room.descTr ?? ''} ${room.roomType ?? ''}'
        .toLowerCase();
    return switch (categoryId) {
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
