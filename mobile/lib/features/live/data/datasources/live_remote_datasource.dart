import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../models/live_stream_dto.dart';
import '../../domain/entities/live_stream_entity.dart';
import '../../domain/entities/voice_room_entity.dart';

class LiveRemoteDataSource {
  LiveRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<LiveStreamEntity>> fetch({int page = 1}) async {
    if (Env.useNextAuth) {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.videoStreams,
        query: {'limit': '50'},
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
      list = pick(body, ['items', 'data', 'streams', 'results', 'lives']);
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
    if (!Env.useNextAuth) return const [];
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

  static const int voiceRoomNormalOpenJetonCost = 200;
  static const int voiceRoomVipOpenJetonCost = 5000;

  static int openRoomJetonCost({required bool vip}) =>
      vip ? voiceRoomVipOpenJetonCost : voiceRoomNormalOpenJetonCost;

  /// canlifal.com `POST /api/chat/rooms/create`
  Future<VoiceRoomEntity> createVoiceChatRoom({bool vip = false}) async {
    final cost = openRoomJetonCost(vip: vip);
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.chatRoomCreate,
      data: {
        'cost': cost,
        'jeton': cost,
        'coins': cost,
        'amount': cost,
        'isVip': vip,
        if (vip) 'vip': true,
        'roomType': vip ? 'vip' : 'normal',
        'type': vip ? 'vip' : 'normal',
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
    if (map['success'] != true) {
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

  Future<String> createVideoStream({
    required String title,
    String? description,
    String? category,
    List<String>? tags,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.videoStreams,
      data: {
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (category != null && category.isNotEmpty) 'category': category,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      },
    );
    final body = res.data;
    Map<String, dynamic>? map;
    if (body is Map<String, dynamic>) {
      map = body;
    } else if (body is Map) {
      map = Map<String, dynamic>.from(body);
    }
    if (map == null) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Geçersiz yayın yanıtı',
      );
    }
    final dataMap = map['data'];
    final id = pick(map, ['id', '_id', 'streamId']) ??
        (dataMap is Map
            ? pick(asJsonMap(Map<String, dynamic>.from(dataMap)),
                ['id', '_id', 'streamId'])
            : null);
    if (id == null || id.toString().isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Yayın oluşturuldu ancak oda kimliği alınamadı',
      );
    }
    final streamId = id.toString();
    try {
      await _dio.safePost<dynamic>(
        '/api/video-streams/$streamId/live-started',
        data: {'title': title},
      );
    } catch (_) {
      // Site uç yoksa sessiz; push canlifal.com backend'inde tetiklenmeli
    }
    return streamId;
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
      id: rawId.isNotEmpty ? rawId : slug,
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
