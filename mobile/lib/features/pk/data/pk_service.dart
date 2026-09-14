import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../../live/data/datasources/live_field/live_field_api_util.dart';
import 'pk_exception.dart';
import 'pk_models.dart';

/// Birleşik PK istemcisi — öncelik `GET/POST /api/live/pk`.
class PkService {
  PkService(this._dio);

  final Dio _dio;

  Duration? _clockSkew;

  Duration get clockSkew => _clockSkew ?? Duration.zero;

  void _applyServerNow(String? serverNow) {
    final server = DateTime.tryParse(serverNow ?? '');
    if (server == null) return;
    _clockSkew = server.difference(DateTime.now());
  }

  Future<PkBattle?> getState(String contextId) async {
    final id = contextId.trim();
    if (id.isEmpty) return null;
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.livePk,
      query: {'roomId': id},
    );
    if (res.data is Map && (res.data as Map)['success'] == true) {
      final data = (res.data as Map)['data'];
      if (data == null) return null;
      if (data is Map) {
        final battle = PkBattle.fromJson(asJsonMap(data));
        _applyServerNow(battle.serverNow);
        return battle.id.isEmpty ? null : battle;
      }
      return null;
    }
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null || map.isEmpty) return null;
    final battle = PkBattle.fromJson(map);
    _applyServerNow(battle.serverNow);
    return battle.id.isEmpty ? null : battle;
  }

  Future<PkBattle> postLivePk(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.livePk, data: body);
    return _parseLivePkResponse(res);
  }

  PkBattle _parseLivePkResponse(Response<dynamic> res) {
    final code = res.statusCode ?? 0;
    if (code >= 400) {
      throw PkException.fromResponse(statusCode: code, body: res.data);
    }
    if (res.data is Map && (res.data as Map)['success'] == false) {
      throw PkException.fromResponse(statusCode: code, body: res.data);
    }
    final map = LiveFieldApiUtil.unwrapData(res.data);
    if (map == null || map.isEmpty) {
      throw const PkException('PK yanıtı boş');
    }
    final battle = PkBattle.fromJson(map);
    _applyServerNow(battle.serverNow);
    if (battle.id.isEmpty) {
      throw const PkException('PK kimliği alınamadı');
    }
    return battle;
  }

  Future<PkBattle> create({
    required String roomId,
    required String targetRoomId,
    int durationSeconds = 180,
  }) =>
      postLivePk({
        'action': 'create',
        'roomId': roomId.trim(),
        'targetRoomId': targetRoomId.trim(),
        'duration': durationSeconds.clamp(60, 600),
      });

  Future<PkBattle> accept(String battleId) => postLivePk({
        'action': 'accept',
        'battleId': battleId.trim(),
      });

  Future<PkBattle> reject(String battleId) => postLivePk({
        'action': 'reject',
        'battleId': battleId.trim(),
      });

  Future<PkBattle> cancel(String battleId) => postLivePk({
        'action': 'cancel',
        'battleId': battleId.trim(),
      });

  Future<PkBattle> end(String battleId) => postLivePk({
        'action': 'end',
        'battleId': battleId.trim(),
      });

  /// Oda içi kullanıcı PK — `POST /api/chat/rooms/{roomId}/pk` `create_user`.
  Future<PkBattle> createUserRoomPk({
    required String roomId,
    required List<String> side1UserIds,
    required List<String> side2UserIds,
    int durationSeconds = 180,
    int countdownSec = 5,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomPk(roomId.trim()),
      data: {
        'action': 'create_user',
        'side1UserIds': side1UserIds,
        'side2UserIds': side2UserIds,
        'duration': durationSeconds.clamp(60, 600),
        'countdownSec': countdownSec.clamp(0, 30),
      },
    );
    final battle = parseUnwrappedBattle(res.data);
    if (battle == null) {
      throw PkException.fromResponse(
        statusCode: res.statusCode,
        body: res.data,
        fallback: 'Oda içi PK başlatılamadı',
      );
    }
    _applyServerNow(battle.serverNow);
    return battle;
  }

  Future<PkCandidatesBundle> streamCandidates(String streamId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamPkCandidates,
      query: {'streamId': streamId.trim()},
    );
    return _parseCandidates(res.data, fromStream: true);
  }

  Future<PkCandidatesBundle> roomCandidates(String roomId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.chatRoomPkCandidates,
      query: {'roomId': roomId.trim()},
    );
    return _parseCandidates(res.data, fromStream: false);
  }

  PkCandidatesBundle _parseCandidates(dynamic body, {required bool fromStream}) {
    Map<String, dynamic>? map;
    if (body is Map) {
      map = asJsonMap(body);
    }
    if (map == null) {
      return const PkCandidatesBundle(candidates: []);
    }
    final list = asJsonList(map['candidates']);
    final items = list
        .map((e) => fromStream
            ? PkCandidate.fromStreamJson(asJsonMap(e))
            : PkCandidate.fromRoomJson(asJsonMap(e)))
        .where((c) => c.contextId.isNotEmpty)
        .toList();
    return PkCandidatesBundle(
      candidates: items,
      selfBusy: map['selfBusy'] == true,
      total: asInt(map['total']),
    );
  }

  /// Zarfsız oda/yayın PK yanıtı (`/api/chat/rooms/.../pk`, `/api/video-streams/pk`).
  static PkBattle? parseUnwrappedBattle(dynamic body) {
    if (body is! Map) return null;
    final map = asJsonMap(body);
    if (map['error'] != null && map['id'] == null) return null;
    final battle = PkBattle.fromJson(map);
    return battle.id.isEmpty ? null : battle;
  }
}
