import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/pk/pk_event_models.dart';
import '../../domain/pk/pk_leaderboard_models.dart';
import '../../domain/pk/pk_room_models.dart';
import '../../domain/pk/pk_unified_bridge.dart';

/// Birleşik `/api/pk/*` (Faz 1–3) — 1v1 davet, çoklu misafir, takım, liderlik.
/// Eski `/api/video-streams/:id/pk-battle` akışını bozmaz; üst katman fallback kullanır.
class PkRoomRemoteDataSource {
  PkRoomRemoteDataSource(this._dio);

  final Dio _dio;

  // --- Faz 1: 1v1 davet / yanıt ---

  /// `POST /api/pk/request` — karşı yayıncıya PK daveti.
  Future<PkRoomMatch?> request({
    required String hostStreamId,
    required String opponentStreamId,
    int durationSec = 180,
    PkRoomMode mode = PkRoomMode.oneVsOne,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.pkRequest,
      data: {
        'hostStreamId': hostStreamId,
        'opponentStreamId': opponentStreamId,
        'durationSec': durationSec,
        'mode': mode.wire,
      },
    );
    return _parse(res.data);
  }

  /// `POST /api/pk/:id/respond` — kabul veya red.
  Future<PkRoomMatch?> respond(
    String id, {
    required String action, // accept | reject
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.pkMatchRespond(id),
      data: {'action': action},
    );
    return _parse(res.data);
  }

  /// Bekleyen davetlerim.
  Future<List<PkRoomMatch>> myInvites() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.pkMeInvites);
    return parsePkMatchList(res.data);
  }

  /// Aktif maçlarım.
  Future<List<PkRoomMatch>> myMatches() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.pkMeMatches);
    return parsePkMatchList(res.data);
  }

  /// Bir yayına ait aktif PK (1v1 dahil).
  Future<PkRoomMatch?> activeForStream(String streamId) async {
    final matches = await active();
    return findStreamPkMatch(matches, streamId);
  }

  // --- Faz 2: çoklu misafir / takım ---

  /// Çoklu misafir / takım PK odası aç (host otomatik koltuk 0).
  Future<PkRoomMatch?> createRoom({
    required String hostStreamId,
    required PkRoomMode mode,
    required int seatCount,
    int? durationSec,
    String? leftName,
    String? rightName,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.pkRoom,
      data: {
        'hostStreamId': hostStreamId,
        'mode': mode.wire,
        'seatCount': seatCount,
        if (durationSec != null) 'durationSec': durationSec,
        if (leftName != null) 'leftName': leftName,
        if (rightName != null) 'rightName': rightName,
      },
    );
    return _parse(res.data);
  }

  /// Oda savaşını başlat (pending → live).
  Future<PkRoomMatch?> start(String id) async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.pkMatchStart(id));
    return _parse(res.data);
  }

  /// Bir koltuğa katıl (team modunda takım zorunlu).
  Future<PkRoomMatch?> joinSeat(
    String id, {
    String? team,
    int? seatIndex,
    String? streamId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.pkMatchSeatsJoin(id),
      data: {
        if (team != null) 'team': team,
        if (seatIndex != null) 'seatIndex': seatIndex,
        if (streamId != null) 'streamId': streamId,
      },
    );
    return _parse(res.data);
  }

  /// Koltuğu bırak (host bırakamaz).
  Future<PkRoomMatch?> leaveSeat(String id) async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.pkMatchSeatsLeave(id));
    return _parse(res.data);
  }

  /// Host: bir kullanıcıyı koltuktan çıkar.
  Future<PkRoomMatch?> kickSeat(String id, {required String userId}) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.pkMatchSeatsKick(id),
      data: {'userId': userId},
    );
    return _parse(res.data);
  }

  /// PK durumu (poll / bootstrap).
  Future<PkRoomMatch?> getMatch(String id) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.pkMatch(id));
    return _parse(res.data);
  }

  /// Odayı bitir.
  Future<PkRoomMatch?> end(String id) async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.pkMatchEnd(id));
    return _parse(res.data);
  }

  /// Bekleyen daveti / odayı iptal.
  Future<PkRoomMatch?> cancel(String id) async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.pkMatchCancel(id));
    return _parse(res.data);
  }

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

  /// PK geçmişim (galibiyet/mağlubiyet/berabere).
  Future<List<PkHistoryEntry>> history({int page = 1, int limit = 30}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.pkMeHistory,
      query: {'page': page, 'limit': limit},
    );
    dynamic raw = res.data;
    if (raw is Map) {
      raw = asJsonMap(raw)['history'] ??
          asJsonMap(raw)['matches'] ??
          asJsonMap(raw)['data'] ??
          asJsonMap(raw)['items'];
    }
    if (raw is! List) return const [];
    final out = <PkHistoryEntry>[];
    for (final e in raw) {
      if (e is Map) out.add(PkHistoryEntry.fromJson(asJsonMap(e)));
    }
    return out;
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

  /// Oda sahibi: premium maç-içi etkinlik başlat.
  Future<PkMatchEvent?> triggerEvent(
    String id, {
    required PkEventType type,
    int? multiplier,
    int? durationSec,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.pkMatchEvents(id),
      data: {
        'type': type.wire,
        if (multiplier != null) 'multiplier': multiplier,
        if (durationSec != null) 'durationSec': durationSec,
      },
    );
    final body = res.data;
    if (body is Map) {
      final m = asJsonMap(body);
      final data = m['event'] is Map ? asJsonMap(m['event']) : m;
      return PkMatchEvent.fromJson(data);
    }
    return null;
  }

  /// Maçın etkinlik geçmişi (aktif/bitmiş).
  Future<List<PkMatchEvent>> events(String id) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.pkMatchEvents(id));
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
  }

  /// PK istatistiklerim (JWT) veya belirli kullanıcının.
  Future<PkStats> stats({String? userId}) async {
    final path = userId == null || userId.isEmpty
        ? ApiEndpoints.pkMeStats
        : ApiEndpoints.pkStatsUser(userId);
    final res = await _dio.safeGet<dynamic>(path);
    final body = res.data;
    if (body is Map) return PkStats.fromJson(asJsonMap(body));
    return const PkStats();
  }

  // --- Moderasyon (admin/yönetici) ---

  Future<void> banUser({
    required String userId,
    String? reason,
    int? durationSec,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.pkAdminBan,
      data: {
        'userId': userId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (durationSec != null) 'durationSec': durationSec,
      },
    );
  }

  Future<void> unban(String userId) async {
    await _dio.safePost<dynamic>(ApiEndpoints.pkAdminUnban(userId));
  }

  Future<List<Map<String, dynamic>>> bans() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.pkAdminBans);
    dynamic raw = res.data;
    if (raw is Map) {
      raw = asJsonMap(raw)['bans'] ??
          asJsonMap(raw)['data'] ??
          asJsonMap(raw)['items'];
    }
    if (raw is! List) return const [];
    return [for (final e in raw) if (e is Map) asJsonMap(e)];
  }

  Future<void> forceEnd(String matchId) async {
    await _dio.safePost<dynamic>(ApiEndpoints.pkAdminForceEnd(matchId));
  }

  Future<void> forceKick(String matchId, String userId) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.pkAdminForceKick(matchId, userId),
    );
  }

  /// Birleşik API kullanılabilir mi? (404 değilse true).
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
