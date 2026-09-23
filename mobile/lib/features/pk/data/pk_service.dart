import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../../live/data/datasources/live_field/live_field_api_util.dart';
import '../../voice_hub/data/datasources/pk_battle_remote_datasource.dart';
import '../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'pk_battle_bridge.dart';
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
        final battle = PkBattle.fromJson(_battleJsonFromPayload(asJsonMap(data)));
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
    final battle = PkBattle.fromJson(_battleJsonFromPayload(map));
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
    final s1 = side1UserIds.where((id) => id.trim().isNotEmpty).take(4).toList();
    final s2 = side2UserIds.where((id) => id.trim().isNotEmpty).take(4).toList();
    if (s1.isEmpty || s2.isEmpty) {
      throw const PkException('PK için her iki tarafta en az bir kullanıcı gerekli');
    }
    final api = PkBattleRemoteDataSource(_dio);
    final remote = await api.createUserInRoomPk(
      roomId: roomId.trim(),
      side1UserIds: s1,
      side2UserIds: s2,
      durationSeconds: durationSeconds,
      countdownSec: countdownSec,
    );
    final battle = remote != null ? pkRemoteToBattle(remote) : null;
    if (battle == null || battle.id.isEmpty) {
      throw const PkException('Oda içi PK başlatılamadı');
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

  Future<PkCandidatesBundle> roomCandidates(
    String roomId, {
    String? alternateRoomId,
  }) async {
    ApiException? lastError;
    for (final key in _roomQueryKeys(roomId, alternateRoomId)) {
      try {
        final res = await _dio.safeGet<dynamic>(
          ApiEndpoints.chatRoomPkCandidates,
          query: {'roomId': key},
        );
        final bundle = _parseCandidates(res.data, fromStream: false);
        if (bundle.candidates.isNotEmpty || bundle.selfBusy) {
          return bundle;
        }
        if (bundle.total > 0) return bundle;
      } on ApiException catch (e) {
        lastError = e;
        if (e.statusCode == 404) continue;
        rethrow;
      }
    }
    if (lastError != null && lastError.statusCode != 404) throw lastError;
    return const PkCandidatesBundle(candidates: []);
  }

  List<String> _roomQueryKeys(String primary, String? alternate) {
    final keys = <String>[];
    void add(String? v) {
      final k = v?.trim() ?? '';
      if (k.isNotEmpty && !keys.contains(k)) keys.add(k);
    }

    add(primary);
    add(alternate);
    return keys;
  }

  PkCandidatesBundle _parseCandidates(dynamic body, {required bool fromStream}) {
    List<dynamic> rawList = const [];
    Map<String, dynamic>? map;

    if (body is List) {
      rawList = body;
    } else if (body is Map) {
      map = asJsonMap(body);
      if (map['success'] == true) {
        final data = map['data'];
        if (data is List) {
          rawList = data;
        } else if (data is Map) {
          map = asJsonMap(data);
        }
      }
      if (rawList.isEmpty) {
        rawList = asJsonList(
          map['candidates'] ??
              map['rooms'] ??
              map['items'] ??
              map['eligibleRooms'] ??
              map['eligible'],
        );
      }
    }

    if (rawList.isEmpty && map == null) {
      return const PkCandidatesBundle(candidates: []);
    }

    final items = rawList
        .map((e) => fromStream
            ? PkCandidate.fromStreamJson(asJsonMap(e))
            : PkCandidate.fromRoomJson(asJsonMap(e)))
        .where((c) => c.contextId.isNotEmpty)
        .toList();
    return PkCandidatesBundle(
      candidates: items,
      selfBusy: map?['selfBusy'] == true,
      total: () {
        final t = asInt(map?['total']);
        return t > 0 ? t : items.length;
      }(),
    );
  }

  static Map<String, dynamic> _battleJsonFromPayload(Map<String, dynamic> json) {
    if (json['id']?.toString().trim().isNotEmpty ?? false) return json;
    for (final key in ['battle', 'pkBattle', 'pk']) {
      final nested = asJsonMap(json[key]);
      if (nested.isNotEmpty && nested['id']?.toString().trim().isNotEmpty == true) {
        return nested;
      }
    }
    return json;
  }

  /// Zarfsız oda/yayın PK yanıtı (`/api/chat/rooms/.../pk`, `/api/video-streams/pk`).
  static PkBattle? parseUnwrappedBattle(dynamic body) {
    final remote = parsePkBattleHttpBody(body);
    if (remote != null && remote.effectiveId.isNotEmpty) {
      return pkRemoteToBattle(remote);
    }
    if (body is! Map) return null;
    final map = PkBattleRemote.normalizeWireMap(asJsonMap(body));
    if (map['error'] != null && map['id'] == null) return null;
    final battle = PkBattle.fromJson(map);
    return battle.id.isEmpty ? null : battle;
  }
}
