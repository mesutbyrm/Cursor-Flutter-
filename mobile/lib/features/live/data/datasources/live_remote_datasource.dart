import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
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
    return asJsonList(list).map(_mapStreamRow).where((s) => s.id.isNotEmpty).toList();
  }

  /// canlifal.com `/api/chat/rooms` — site ile aynı oda kartları.
  Future<List<VoiceRoomEntity>> fetchVoiceRooms() async {
    if (!Env.useNextAuth) return const [];
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.chatRooms);
    final body = res.data;
    if (body is! List) return const [];
    return asJsonList(body).map(_mapVoiceRoom).where((r) => r.id.isNotEmpty).toList();
  }

  Future<VoiceRoomEntity?> fetchVoiceRoomById(String id) async {
    final rooms = await fetchVoiceRooms();
    for (final r in rooms) {
      if (r.id == id || r.slug == id) return r;
    }
    return null;
  }

  LiveStreamEntity _mapStreamRow(Map<String, dynamic> json) {
    final titleRaw = pick(json, ['title', 'name', 'description'])?.toString();
    final title = (titleRaw != null && titleRaw.trim().isNotEmpty)
        ? titleRaw.trim()
        : 'Canlı yayın';

    final thumb = pick(json, [
          'thumbnailUrl',
          'thumbnail',
          'coverUrl',
          'imageUrl',
          'broadcastImage',
          'backgroundUrl',
        ])
        as String?;

    final status = pick(json, ['status'])?.toString().toLowerCase();
    final isLive = pick(json, ['isLive']) == true ||
        status == 'live' ||
        (status == null && pick(json, ['endedAt']) == null);

    return LiveStreamEntity(
      id: pick(json, ['id', '_id', 'streamId'])?.toString() ?? '',
      title: title,
      streamerName: () {
        final u = pick(json, ['user', 'streamer', 'host']);
        if (u is Map) {
          final m = asJsonMap(u);
          return pick(m, ['displayName', 'username', 'name'])?.toString();
        }
        return pick(json, ['streamerName', 'hostName', 'username'])?.toString();
      }(),
      thumbnailUrl: thumb,
      viewerCount: asInt(pick(json, ['viewerCount', 'viewers', 'watching'])),
      isLive: isLive,
    );
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
    return id.toString();
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
    return VoiceRoomEntity(
      id: pick(json, ['id'])?.toString() ?? '',
      slug: pick(json, ['slug'])?.toString() ?? '',
      nameTr: pick(json, ['nameTr', 'nameEn', 'name', 'slug'])?.toString() ?? 'Oda',
      descTr: pick(json, ['descTr', 'descEn', 'description']) as String?,
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
