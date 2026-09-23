import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/pk/pk_event_models.dart';
import '../../domain/pk/pk_leaderboard_models.dart';
import '../../domain/pk/pk_room_models.dart';
import '../../domain/pk/pk_unified_bridge.dart';

/// Canlı / birleşik PK — yalnızca üretimde var olan `/api/video-streams/pk`,
/// `/api/live/pk`, `/api/pk/{matchId}`, `/api/pk/me/invites`, `/api/pk/active`.
class PkRoomRemoteDataSource {
  PkRoomRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PkRoomMatch?> _postVideoPk(Map<String, dynamic> body) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamPk,
        data: body,
      );
      return _parse(res.data);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) return null;
      rethrow;
    }
  }

  Future<PkRoomMatch?> _postLivePk(Map<String, dynamic> body) async {
    try {
      final res = await _dio.safePost<dynamic>(ApiEndpoints.livePk, data: body);
      return _parse(res.data);
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 405) return null;
      rethrow;
    }
  }

  Future<PkRoomMatch?> _mutateMatch(
    String matchId, {
    required String action,
    Map<String, dynamic>? extra,
  }) async {
    final id = matchId.trim();
    if (id.isEmpty) return null;
    final body = {
      'action': action,
      'battleId': id,
      'matchId': id,
      if (extra != null) ...extra,
    };
    return _postVideoPk(body) ?? _postLivePk(body);
  }

  // --- Faz 1: 1v1 davet / yanıt ---

  /// Canlı yayın PK daveti — `POST /api/video-streams/pk`.
  Future<PkRoomMatch?> request({
    required String hostStreamId,
    required String opponentStreamId,
    int durationSec = 180,
    PkRoomMode mode = PkRoomMode.oneVsOne,
  }) async {
    final duration = durationSec.clamp(60, 600);
    final body = {
      'action': 'create',
      'streamId': hostStreamId.trim(),
      'hostStreamId': hostStreamId.trim(),
      'targetStreamId': opponentStreamId.trim(),
      'opponentStreamId': opponentStreamId.trim(),
      'durationSec': duration,
      'duration': duration,
      'mode': mode.wire,
    };
    return _postVideoPk(body) ??
        _postLivePk({
          ...body,
          'roomId': hostStreamId.trim(),
          'targetRoomId': opponentStreamId.trim(),
        });
  }

  /// Kabul veya red — tek uç: `POST /api/video-streams/pk` (yedek `/api/live/pk`).
  Future<PkRoomMatch?> respond(
    String id, {
    required String action, // accept | reject
  }) =>
      _mutateMatch(id, action: action);

  /// Bekleyen davetlerim — cache kapalı.
  Future<List<PkRoomMatch>> myInvites() async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.pkMeInvites,
      forceRefresh: true,
      query: {'direction': 'incoming'},
      options: Options(
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );
    return parsePkMatchList(res.data);
  }

  /// Aktif maçlarım — `GET /api/pk/active` listesinden.
  Future<List<PkRoomMatch>> myMatches() async {
    return active();
  }

  /// Bir yayına ait aktif PK (1v1 dahil).
  Future<PkRoomMatch?> activeForStream(String streamId) async {
    final matches = await active();
    return findStreamPkMatch(matches, streamId);
  }

  // --- Faz 2: çoklu misafir / takım (video-streams action) ---

  Future<PkRoomMatch?> createRoom({
    required String hostStreamId,
    required PkRoomMode mode,
    required int seatCount,
    int? durationSec,
    String? leftName,
    String? rightName,
  }) async {
    return _postVideoPk({
      'action': 'create_room',
      'hostStreamId': hostStreamId.trim(),
      'streamId': hostStreamId.trim(),
      'mode': mode.wire,
      'seatCount': seatCount,
      if (durationSec != null) 'durationSec': durationSec.clamp(60, 600),
      if (leftName != null) 'leftName': leftName,
      if (rightName != null) 'rightName': rightName,
    });
  }

  Future<PkRoomMatch?> start(String id) => _mutateMatch(id, action: 'start');

  Future<PkRoomMatch?> joinSeat(
    String id, {
    String? team,
    int? seatIndex,
    String? streamId,
  }) async {
    return _mutateMatch(
      id,
      action: 'join_seat',
      extra: {
        if (team != null) 'team': team,
        if (seatIndex != null) 'seatIndex': seatIndex,
        if (streamId != null) 'streamId': streamId,
      },
    );
  }

  Future<PkRoomMatch?> leaveSeat(String id) =>
      _mutateMatch(id, action: 'leave_seat');

  Future<PkRoomMatch?> kickSeat(String id, {required String userId}) async {
    return _mutateMatch(
      id,
      action: 'kick_seat',
      extra: {'userId': userId},
    );
  }

  /// PK durumu (poll / bootstrap).
  Future<PkRoomMatch?> getMatch(String id) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.pkMatch(id));
    return _parse(res.data);
  }

  Future<PkRoomMatch?> end(String id) => _mutateMatch(id, action: 'end');

  Future<PkRoomMatch?> cancel(String id) => _mutateMatch(id, action: 'cancel');

  /// Aktif PK maçları — önce `/api/live/pk/active`, yedek `/api/pk/active`.
  Future<List<PkRoomMatch>> active() async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.livePkActive,
        forceRefresh: true,
      );
      return parsePkMatchList(res.data);
    } catch (_) {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.pkActive);
      return parsePkMatchList(res.data);
    }
  }

  /// PK geçmişi — üretimde ayrı history ucu yok; boş liste.
  Future<List<PkHistoryEntry>> history({int page = 1, int limit = 30}) async {
    return const [];
  }

  /// PK liderlik tablosu.
  Future<List<PkLeaderboardEntry>> leaderboard({
    String period = 'weekly',
    String metric = 'score',
    int limit = 100,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.pkLeaderboard,
      query: {'period': period, 'metric': metric, 'limit': limit},
    );
    dynamic raw = res.data;
    if (raw is Map) {
      raw = asJsonMap(raw)['entries'] ??
          asJsonMap(raw)['data'] ??
          asJsonMap(raw)['leaderboard'];
    }
    if (raw is! List) return const [];
    final out = <PkLeaderboardEntry>[];
    var i = 0;
    for (final e in raw) {
      if (e is Map) {
        i++;
        out.add(PkLeaderboardEntry.fromJson(asJsonMap(e), i));
      }
    }
    return out;
  }

  Future<PkMatchEvent?> triggerEvent(
    String id, {
    required PkEventType type,
    int? multiplier,
    int? durationSec,
  }) async {
    final match = await _mutateMatch(
      id,
      action: 'trigger_event',
      extra: {
        'type': type.wire,
        if (multiplier != null) 'multiplier': multiplier,
        if (durationSec != null) 'durationSec': durationSec,
      },
    );
    if (match == null) return null;
    return null;
  }

  Future<List<PkMatchEvent>> events(String id) async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.pkMatchStream(id));
      dynamic raw = res.data;
      if (raw is Map) {
        raw = asJsonMap(raw)['events'] ??
            asJsonMap(raw)['data'] ??
            asJsonMap(raw)['items'];
      }
      if (raw is! List) return const [];
      final out = <PkMatchEvent>[];
      for (final e in raw) {
        if (e is Map) out.add(PkMatchEvent.fromJson(asJsonMap(e)));
      }
      return out;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  Future<PkStats> stats({String? userId}) async {
    return const PkStats();
  }

  // --- Moderasyon: üretimde mobil admin PK uçları yok ---

  Future<void> banUser({
    required String userId,
    String? reason,
    int? durationSec,
  }) async {
    throw const ApiException(
      'PK moderasyonu bu sürümde kullanılamıyor',
      statusCode: 404,
    );
  }

  Future<void> unban(String userId) async {
    throw const ApiException(
      'PK moderasyonu bu sürümde kullanılamıyor',
      statusCode: 404,
    );
  }

  Future<List<Map<String, dynamic>>> bans() async => const [];

  Future<void> forceEnd(String matchId) async {
    await end(matchId);
  }

  Future<void> forceKick(String matchId, String userId) async {
    await kickSeat(matchId, userId: userId);
  }

  Future<bool> isUnifiedApiAvailable() async {
    try {
      await _dio.safeGet<dynamic>(ApiEndpoints.pkActive);
      return true;
    } on ApiException catch (e) {
      return e.statusCode != 404;
    } catch (_) {
      return false;
    }
  }

  PkRoomMatch? _parse(dynamic body) {
    if (body is Map) {
      final m = asJsonMap(body);
      if ((m['id'] == null) &&
          m['match'] == null &&
          m['success'] == true &&
          m['data'] is Map) {
        return PkRoomMatch.fromJson(asJsonMap(m['data']));
      }
      return PkRoomMatch.fromJson(m);
    }
    return null;
  }
}
