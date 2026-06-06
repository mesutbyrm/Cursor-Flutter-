import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/live_debug_log.dart';
import '../../../../core/util/json_util.dart';
import '../models/live_stream_dto.dart';
import '../../domain/entities/live_stream_chat_message.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/entities/voice_room_entity.dart';

class LiveRemoteDataSource {
  LiveRemoteDataSource(this._dio);

  final Dio _dio;

  static const int _pageSize = 30;

  Future<List<LiveStreamEntity>> fetch({int page = 1}) async {
    if (Env.useMobileAuth) {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreams,
        query: {'limit': '$_pageSize', 'page': '$page'},
      );
      return _parseStreamList(res.data);
    }
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.liveStreams,
      query: {'page': page, 'limit': 30},
    );
    return _parseStreamList(res.data);
  }

  List<LiveStreamEntity> _parseStreamList(dynamic body) {
    dynamic list;
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] != null) {
        return _parseStreamList(body['data']);
      }
      list = pick(body, [
        'videoStreams',
        'streams',
        'items',
        'data',
        'results',
        'lives',
      ]);
    } else {
      list = body;
    }
    return asJsonList(list)
        .map((j) => LiveStreamDto.fromApiMap(j).toEntity())
        .where((s) => s.id.isNotEmpty)
        .toList();
  }

  /// canlifal.com `/api/chat/rooms` — site ile aynı oda kartları.
  Future<List<VoiceRoomEntity>> fetchVoiceRooms() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.chatRooms);
    final body = res.data;
    dynamic list = body;
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'];
        list = data is Map ? pick(asJsonMap(data), ['rooms']) : data;
      } else {
        list = pick(body, ['rooms', 'items', 'data']) ?? body;
      }
    }
    if (list is! List) return const [];
    return asJsonList(list)
        .map(_mapVoiceRoom)
        .where((r) => r.apiRoomKey.isNotEmpty)
        .toList();
  }

  static const int voiceRoomNormalOpenJetonCost = 100;
  static const int voiceRoomVipOpenJetonCost = 5000;

  static int openRoomJetonCost({required bool vip}) =>
      vip ? voiceRoomVipOpenJetonCost : voiceRoomNormalOpenJetonCost;

  /// canlifal.com `POST /api/chat/rooms/create`
  Future<VoiceRoomEntity> createVoiceChatRoom({
    bool vip = false,
    String? roomName,
  }) async {
    final cost = openRoomJetonCost(vip: vip);
    final name = roomName?.trim();
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomCreate,
      data: {
        'cost': cost,
        'jeton': cost,
        'jetonCost': cost,
        'coins': cost,
        'amount': cost,
        'isVip': vip,
        if (vip) 'vip': true,
        'roomType': vip ? 'vip' : 'normal',
        'type': vip ? 'vip' : 'normal',
        if (name != null && name.isNotEmpty) ...{
          'name': name,
          'nameTr': name,
          'title': name,
          'roomName': name,
        },
      },
    );
    final body = res.data;
    if (body is String &&
        (body.contains('<!DOCTYPE') || body.contains('<html'))) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Oda açılamadı — oturum gerekli',
      );
    }
    Map<String, dynamic>? map;
    if (body is Map<String, dynamic>) {
      map = body;
    } else if (body is Map) {
      map = Map<String, dynamic>.from(body);
    }
    if (map == null) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Geçersiz oda oluşturma yanıtı',
      );
    }
    if (map['success'] == false) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: _formatCreateRoomError(map),
      );
    }
    final httpCode = res.statusCode ?? 0;
    if (map['success'] != true && httpCode != 201) {
      final err = (map['error'] ?? map['message'])?.toString().trim();
      if (err != null && err.isNotEmpty) {
        throw DioException(
          requestOptions: res.requestOptions,
          message: err,
        );
      }
    }
    dynamic roomRaw = map['room'] ?? map['data'];
    if (roomRaw is Map && roomRaw['room'] is Map) {
      roomRaw = roomRaw['room'];
    }
    if (roomRaw is Map) {
      return _mapVoiceRoom(asJsonMap(roomRaw));
    }
    if (map.containsKey('id') || map.containsKey('slug')) {
      return _mapVoiceRoom(map);
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Oda oluşturuldu ancak oda bilgisi alınamadı',
    );
  }

  static String _formatCreateRoomError(Map<String, dynamic> map) {
    final raw = map['error'] ?? map['message'] ?? map['detail'];
    final msg = raw?.toString().trim();
    if (msg != null && msg.isNotEmpty) return msg;
    return 'Oda açılamadı. Jeton bakiyenizi ve oturumunuzu kontrol edin.';
  }

  Future<VoiceRoomEntity?> fetchVoiceRoomById(String id) async {
    final rooms = await fetchVoiceRooms();
    final needle = id.trim().toLowerCase();
    if (needle.isEmpty) return null;
    String norm(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'-+$'), '');
    for (final r in rooms) {
      if (r.id == id ||
          r.slug == id ||
          r.id.toLowerCase() == needle ||
          r.slug.toLowerCase() == needle ||
          norm(r.slug) == norm(id) ||
          norm(r.id) == norm(id)) {
        return r;
      }
    }
    return null;
  }

  Future<LiveStreamEntity?> fetchStream(String streamId) async {
    if (!Env.useMobileAuth) return null;
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStream(streamId),
      );
      final body = res.data;
      if (body is Map<String, dynamic>) {
        final raw = body['stream'] ?? body['data'] ?? body;
        if (raw is Map) {
          return LiveStreamDto.fromApiMap(Map<String, dynamic>.from(raw))
              .toEntity();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<int> joinVideoStream(String streamId) async {
    LiveDebugLog.log('stream.join', {'streamId': streamId});
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamJoin(streamId),
    );
    final body = res.data;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      return asInt(pick(data, ['viewerCount', 'viewers', 'watching']));
    }
    return 0;
  }

  Future<void> leaveVideoStream(String streamId) async {
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.videoStreamLeave(streamId));
      LiveDebugLog.log('stream.leave', {'streamId': streamId});
    } catch (_) {}
  }

  Future<List<LiveStreamChatMessage>> fetchStreamMessages(
    String streamId, {
    DateTime? since,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.videoStreamMessages(streamId),
      query: since != null
          ? {'since': since.toUtc().toIso8601String()}
          : null,
    );
    return _parseStreamMessages(res.data);
  }

  Future<LiveStreamChatMessage?> sendStreamMessage({
    required String streamId,
    required String content,
  }) async {
    LiveDebugLog.log('stream.chat.send', {'streamId': streamId});
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreamMessages(streamId),
      data: {'content': content.trim()},
    );
    final body = res.data;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final raw = map['message'] ?? map['data'];
      if (raw is Map) {
        return LiveStreamChatMessage.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
    }
    return null;
  }

  List<LiveStreamChatMessage> _parseStreamMessages(dynamic body) {
    dynamic list;
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      if (map['success'] == true && map['data'] != null) {
        return _parseStreamMessages(map['data']);
      }
      list = pick(map, ['messages', 'items', 'data']);
    } else {
      list = body;
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => LiveStreamChatMessage.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .where((m) => m.content.isNotEmpty)
        .toList();
  }

  Future<String> createVideoStream({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
    String? thumbnailUrl,
  }) async {
    final started = DateTime.now();
    LiveDebugLog.log('create.request', {'title': title});
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreams,
      data: {
        'title': title,
        'name': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (category != null && category.isNotEmpty) 'category': category,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          'thumbnailUrl': thumbnailUrl,
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
          'coverUrl': thumbnailUrl,
        'requestType': 'live',
        'status': 'live',
      },
    );
    final streamId = _extractStreamId(res.data);
    if (streamId == null || streamId.isEmpty) {
      throw ApiException(
        'Yayın oluşturuldu ancak oda kimliği alınamadı. '
        'Yanıt: ${res.statusCode}',
      );
    }
    LiveDebugLog.log('create.ok', {
      'streamId': streamId,
      'elapsedMs': DateTime.now().difference(started).inMilliseconds,
    });
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.videoStreamLiveStarted(streamId),
        data: {'title': title},
      );
      LiveDebugLog.log('live-started.ok', {'streamId': streamId});
    } catch (e) {
      LiveDebugLog.log('live-started.skip', {
        'streamId': streamId,
        'reason': ApiException.userMessage(e),
      });
    }
    return streamId;
  }

  String? _extractStreamId(dynamic body) {
    if (body is String && body.trim().isNotEmpty && !body.contains('<html')) {
      return body.trim();
    }
    Map<String, dynamic>? map;
    if (body is Map<String, dynamic>) {
      map = body;
    } else if (body is Map) {
      map = Map<String, dynamic>.from(body);
    }
    if (map == null) return null;
    if (map['success'] == true && map['data'] != null) {
      return _extractStreamId(map['data']);
    }
    final streamObj = map['stream'] ?? map['videoStream'] ?? map['broadcast'];
    if (streamObj is Map) {
      final nested = _extractStreamId(streamObj);
      if (nested != null) return nested;
    }
    final id = pick(map, ['id', '_id', 'streamId', 'roomId']);
    return id?.toString();
  }

  Future<void> endVideoStream(String streamId) async {
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.videoStreamEnd(streamId));
    } catch (_) {
      await _dio.safeDelete<dynamic>('/api/video-streams/$streamId');
    }
  }

  VoiceRoomEntity _mapVoiceRoom(Map<String, dynamic> json) {
    final o = pick(json, ['owner']);
    String? ownerName;
    String? ownerAvatar;
    if (o is Map) {
      final om = asJsonMap(o);
      ownerName = jsonDisplayLabel(om);
      ownerAvatar = pick(om, ['image', 'avatar', 'avatarUrl'])?.toString();
    }
    final recent = <String>[];
    final ru = json['recentUsers'];
    if (ru is List) {
      for (final u in ru) {
        if (u is Map) {
          final m = asJsonMap(u);
          final img = pick(m, ['image', 'avatar'])?.toString();
          if (img != null && img.isNotEmpty) recent.add(img);
        }
      }
    }
    final djIds = <String>[];
    final djRaw = pick(json, ['djUserIds']);
    if (djRaw is List) {
      for (final id in djRaw) {
        if (id != null) djIds.add(id.toString());
      }
    } else if (djRaw is String && djRaw.startsWith('[')) {
      try {
        final decoded = djRaw
            .replaceAll('"', '')
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',');
        for (final p in decoded) {
          final s = p.trim();
          if (s.isNotEmpty) djIds.add(s);
        }
      } catch (_) {}
    }
    final slug = pick(json, ['slug'])?.toString() ?? '';
    final rawId = pick(json, ['id', '_id', 'roomId'])?.toString() ?? '';
    return VoiceRoomEntity(
      id: rawId,
      slug: slug,
      nameTr: pick(json, ['nameTr', 'nameEn', 'name', 'slug'])?.toString() ?? 'Oda',
      descTr: pick(json, ['descTr', 'descEn', 'description']) as String?,
      rulesTr: pick(json, ['rules', 'rulesTr', 'roomRules']) as String?,
      icon: pick(json, ['icon']) as String?,
      onlineCount: asInt(pick(json, ['onlineCount'])),
      userCount: asInt(pick(json, ['userCount'])),
      backgroundImageUrl: pick(json, ['backgroundImage']) as String?,
      ownerName: ownerName,
      ownerAvatarUrl: ownerAvatar,
      ownerId: pick(json, ['ownerId'])?.toString() ??
          (o is Map ? pick(asJsonMap(o), ['id'])?.toString() : null),
      activeDjId: pick(json, ['activeDjId'])?.toString(),
      djUserIds: djIds,
      recentUserAvatars: recent,
    );
  }
}
