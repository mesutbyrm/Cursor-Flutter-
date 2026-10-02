import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../domain/room_access_models.dart';

/// VIP şifreli oda uçları (`/api/live/rooms/{id}/...`).
///
/// Hata gövdeleri (`{success:false, error:{code, message, remainingAttempts}}`)
/// okunabilsin diye her istek `validateStatus: true` ile yapılır.
class RoomAccessRemoteDataSource {
  RoomAccessRemoteDataSource(this._dio);

  final Dio _dio;

  static final _anyStatus = Options(validateStatus: (_) => true);

  Future<RoomAccessStatus> status(String roomKey) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.liveRoomVerifyPassword(roomKey),
      options: _anyStatus,
    );
    final data = _data(res);
    if (res.statusCode == 404 || data == null) {
      // Sunucu bu uca sahip değil / oda yok: kapıyı açma kararı vermeyiz.
      throw _toException(res, 'Oda erişim durumu alınamadı');
    }
    if (data['passwordProtected'] != true) return RoomAccessStatus.open;
    return RoomAccessStatus(
      passwordProtected: true,
      maxAttempts: _int(data['maxAttempts']) ?? 3,
      remainingAttempts: _int(data['remainingAttempts']) ?? 3,
      locked: data['locked'] == true,
      bypass: data['bypass'] == true,
      joinRequestStatus: data['joinRequestStatus']?.toString(),
    );
  }

  Future<PasswordVerifyResult> verifyPassword(
    String roomKey,
    String password,
  ) async {
    final res = await _dio.post<dynamic>(
      ApiEndpoints.liveRoomVerifyPassword(roomKey),
      data: {'password': password},
      options: _anyStatus,
    );
    final data = _data(res);
    if (res.statusCode == 200 && data?['accessToken'] != null) {
      final exp = _int(data!['expiresAt']);
      return PasswordVerified(
        accessToken: data['accessToken'].toString(),
        expiresAt: exp != null
            ? DateTime.fromMillisecondsSinceEpoch(exp)
            : DateTime.now().add(const Duration(minutes: 4)),
      );
    }
    final err = _error(res);
    final code = err?['code']?.toString();
    if (code == 'INVALID_ROOM_PASSWORD' ||
        code == 'PASSWORD_ATTEMPTS_EXHAUSTED') {
      return PasswordRejected(
        remainingAttempts: _int(err?['remainingAttempts']) ?? 0,
        locked: err?['locked'] == true || code == 'PASSWORD_ATTEMPTS_EXHAUSTED',
        message: err?['message']?.toString() ?? 'Şifre yanlış.',
      );
    }
    throw _toException(res, 'Şifre doğrulanamadı');
  }

  Future<JoinRequestSent> requestJoin(String roomKey) async {
    final res = await _dio.post<dynamic>(
      ApiEndpoints.liveRoomJoinRequest(roomKey),
      data: const <String, dynamic>{},
      options: _anyStatus,
    );
    if (res.statusCode == 409) {
      final err = _error(res);
      return JoinRequestSent(
        requestId: '',
        alreadySent: true,
        state: parseJoinRequestState(err?['status']),
      );
    }
    final data = _data(res);
    if (res.statusCode == 200 && data?['requestId'] != null) {
      return JoinRequestSent(
        requestId: data!['requestId'].toString(),
        alreadySent: false,
        state: parseJoinRequestState(data['status']),
      );
    }
    throw _toException(res, 'İstek gönderilemedi');
  }

  /// İstek sahibi: kendi isteğinin durumu.
  Future<({JoinRequestState? state, bool allowed})> myRequest(
    String roomKey,
  ) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.liveRoomJoinRequest(roomKey),
      options: _anyStatus,
    );
    final data = _data(res);
    if (res.statusCode != 200 || data == null) {
      throw _toException(res, 'İstek durumu alınamadı');
    }
    final req = data['request'];
    return (
      state: req is Map ? parseJoinRequestState(req['status']) : null,
      allowed: data['allowed'] == true,
    );
  }

  /// Oda sahibi / yönetici: bekleyen istekler.
  Future<List<PendingJoinRequest>> pending(String roomKey) async {
    final res = await _dio.get<dynamic>(
      ApiEndpoints.liveRoomJoinRequest(roomKey),
      options: _anyStatus,
    );
    final data = _data(res);
    final list = data?['requests'];
    if (res.statusCode != 200 || list is! List) return const [];
    final out = <PendingJoinRequest>[];
    for (final raw in list) {
      if (raw is! Map) continue;
      final u = raw['user'];
      final user = u is Map ? Map<String, dynamic>.from(u) : const {};
      final userId = user['id']?.toString() ?? '';
      final id = raw['id']?.toString() ?? '';
      if (id.isEmpty || userId.isEmpty) continue;
      out.add(
        PendingJoinRequest(
          id: id,
          userId: userId,
          name: user['name']?.toString() ?? 'Kullanıcı',
          username: user['username']?.toString(),
          avatarUrl: user['image']?.toString(),
        ),
      );
    }
    return out;
  }

  Future<void> respond(
    String roomKey,
    String requestId, {
    required bool approve,
  }) async {
    final path = approve
        ? ApiEndpoints.liveRoomJoinRequestApprove(roomKey, requestId)
        : ApiEndpoints.liveRoomJoinRequestReject(roomKey, requestId);
    final res = await _dio.post<dynamic>(
      path,
      data: const <String, dynamic>{},
      options: _anyStatus,
    );
    // 409 ALREADY_RESOLVED: başka bir yönetici yanıtladı — sorun değil.
    if (res.statusCode == 200 || res.statusCode == 409) return;
    throw _toException(res, 'İşlem yapılamadı');
  }

  // ── yardımcılar ──────────────────────────────────────────────────────────
  static Map<String, dynamic>? _data(Response<dynamic> res) {
    final body = res.data;
    if (body is Map && body['data'] is Map) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }
    return null;
  }

  static Map<String, dynamic>? _error(Response<dynamic> res) {
    final body = res.data;
    if (body is Map && body['error'] is Map) {
      return Map<String, dynamic>.from(body['error'] as Map);
    }
    return null;
  }

  static int? _int(Object? v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');

  static ApiException _toException(Response<dynamic> res, String fallback) {
    final err = _error(res);
    final msg = err?['message']?.toString();
    return ApiException(
      msg != null && msg.isNotEmpty ? msg : fallback,
      statusCode: res.statusCode,
      errorCode: err?['code']?.toString(),
    );
  }
}
