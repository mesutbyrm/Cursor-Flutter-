import 'package:dio/dio.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/pk/pk_event_models.dart';
import '../../domain/pk/pk_leaderboard_models.dart';
import '../../domain/pk/pk_room_models.dart';

/// PK Faz 2 — birleşik `/api/pk/*` (çoklu misafir & takım) uçları.
/// Mevcut 1v1 PK akışını bozmadan additive çalışır.
class PkRoomRemoteDataSource {
  PkRoomRemoteDataSource(this._dio);

  final Dio _dio;

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
      '/api/pk/room',
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
    final res = await _dio.safePost<dynamic>('/api/pk/$id/start');
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
      '/api/pk/$id/seats/join',
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
    final res = await _dio.safePost<dynamic>('/api/pk/$id/seats/leave');
    return _parse(res.data);
  }

  /// Host: bir kullanıcıyı koltuktan çıkar.
  Future<PkRoomMatch?> kickSeat(String id, {required String userId}) async {
    final res = await _dio.safePost<dynamic>(
      '/api/pk/$id/seats/kick',
      data: {'userId': userId},
    );
    return _parse(res.data);
  }

  /// PK durumu (poll).
  Future<PkRoomMatch?> getMatch(String id) async {
    final res = await _dio.safeGet<dynamic>('/api/pk/$id');
    return _parse(res.data);
  }

  /// Odayı iptal / bitir.
  Future<PkRoomMatch?> end(String id) async {
    final res = await _dio.safePost<dynamic>('/api/pk/$id/end');
    return _parse(res.data);
  }

  Future<PkRoomMatch?> cancel(String id) async {
    final res = await _dio.safePost<dynamic>('/api/pk/$id/cancel');
    return _parse(res.data);
  }

  /// Aktif PK maçları (varsa ilgili yayına ait olan).
  Future<List<PkRoomMatch>> active() async {
    final res = await _dio.safeGet<dynamic>('/api/pk/active');
    dynamic raw = res.data;
    if (raw is Map) raw = asJsonMap(raw)['matches'] ?? asJsonMap(raw)['data'];
    if (raw is! List) return const [];
    final out = <PkRoomMatch>[];
    for (final e in raw) {
      if (e is Map) out.add(PkRoomMatch.fromJson(asJsonMap(e)));
    }
    return out;
  }

  /// PK geçmişim (galibiyet/mağlubiyet/berabere).
  Future<List<PkHistoryEntry>> history({int page = 1, int limit = 30}) async {
    final res = await _dio.safeGet<dynamic>(
      '/api/pk/me/history',
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
    String period = 'weekly', // weekly | monthly | season | alltime
    String metric = 'score', // score | wins
    int limit = 100,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      '/api/pk/leaderboard',
      query: {'period': period, 'metric': metric, 'limit': limit},
    );
    dynamic raw = res.data;
    if (raw is Map) {
      raw = asJsonMap(raw)['entries'] ?? asJsonMap(raw)['data'] ?? asJsonMap(raw)['leaderboard'];
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
      '/api/pk/$id/events',
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
    final res = await _dio.safeGet<dynamic>('/api/pk/$id/events');
    dynamic raw = res.data;
    if (raw is Map) {
      raw = asJsonMap(raw)['events'] ?? asJsonMap(raw)['data'] ?? asJsonMap(raw)['items'];
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
        ? '/api/pk/me/stats'
        : '/api/pk/stats/$userId';
    final res = await _dio.safeGet<dynamic>(path);
    final body = res.data;
    if (body is Map) return PkStats.fromJson(asJsonMap(body));
    return const PkStats();
  }

  // --- Moderasyon (admin/yönetici) ---

  /// Bir kullanıcıyı PK sisteminden yasakla.
  Future<void> banUser({
    required String userId,
    String? reason,
    int? durationSec,
  }) async {
    await _dio.safePost<dynamic>(
      '/api/pk/admin/ban',
      data: {
        'userId': userId,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        if (durationSec != null) 'durationSec': durationSec,
      },
    );
  }

  /// Yasağı kaldır.
  Future<void> unban(String userId) async {
    await _dio.safePost<dynamic>('/api/pk/admin/unban/$userId');
  }

  /// Aktif ban listesi (ham map — esnek).
  Future<List<Map<String, dynamic>>> bans() async {
    final res = await _dio.safeGet<dynamic>('/api/pk/admin/bans');
    dynamic raw = res.data;
    if (raw is Map) {
      raw = asJsonMap(raw)['bans'] ?? asJsonMap(raw)['data'] ?? asJsonMap(raw)['items'];
    }
    if (raw is! List) return const [];
    return [for (final e in raw) if (e is Map) asJsonMap(e)];
  }

  /// Bir maçı zorla bitir.
  Future<void> forceEnd(String matchId) async {
    await _dio.safePost<dynamic>('/api/pk/admin/$matchId/force-end');
  }

  /// Bir kullanıcıyı koltuktan zorla çıkar.
  Future<void> forceKick(String matchId, String userId) async {
    await _dio.safePost<dynamic>('/api/pk/admin/$matchId/force-kick/$userId');
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
