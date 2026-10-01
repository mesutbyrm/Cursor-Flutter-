import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';

/// Oda içi PK — ham sunucu yanıtı ile çalışır (`GET/POST /api/chat/rooms/{id}/pk`).
///
/// Mevcut `PkBattleRemoteDataSource` yanıtı `PkBattleRemote`'a indirger ve
/// takım/katılımcı/sunucu-saati alanlarını kaybeder; oda içi PK ekranı bu
/// alanlara ihtiyaç duyar, bu yüzden ayrı ve ince bir istemci kullanılır.
class PkRoomApi {
  PkRoomApi(this._dio);

  final Dio _dio;

  /// Oda anahtarı adayları (önce asıl, sonra alternatif/slug).
  static List<String> keyCandidates(String roomId, String? alternate) {
    final out = <String>[];
    for (final k in [roomId, alternate ?? '']) {
      final t = k.trim();
      if (t.isNotEmpty && !out.contains(t)) out.add(t);
    }
    return out;
  }

  /// Odadaki güncel PK (varsa). Sunucu bu çağrıda süresi dolan PK'yı da
  /// kapatır (`finalizeExpiredActivePKs`) — zaman aşımı sonrası doğru kaynak.
  Future<Map<String, dynamic>?> fetchCurrent(
    String roomId, {
    String? alternateRoomId,
  }) async {
    for (final key in keyCandidates(roomId, alternateRoomId)) {
      try {
        final res = await _dio.safeGet<dynamic>(
          ApiEndpoints.chatRoomPk(key),
          forceRefresh: true,
        );
        final data = res.data;
        if (data == null) return null;
        return _map(data);
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) continue;
        rethrow;
      }
    }
    return null;
  }

  /// PK'yı sunucuda bitirir. Başarısızlıkta [ApiException] fırlatır.
  Future<void> end(
    String roomId,
    String battleId, {
    String? alternateRoomId,
  }) async {
    ApiException? last;
    for (final key in keyCandidates(roomId, alternateRoomId)) {
      try {
        await _dio.safePost<dynamic>(
          ApiEndpoints.chatRoomPk(key),
          data: {'action': 'end', 'battleId': battleId, 'matchId': battleId},
        );
        return;
      } on ApiException catch (e) {
        if (e.statusCode == 404 || e.statusCode == 405) {
          last = e;
          continue;
        }
        rethrow;
      }
    }
    if (last != null) throw last;
  }

  static Map<String, dynamic>? _map(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
      return body;
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return null;
  }
}
