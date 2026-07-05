import 'package:dio/dio.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
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
