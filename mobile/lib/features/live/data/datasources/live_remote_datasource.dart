import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
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

  /// `/api/chat/rooms` — canlifal.com’da girişsiz de JSON liste döner; diğer ortamlarda yoksa boş döner.
  Future<List<VoiceRoomEntity>> fetchVoiceRooms() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.chatRooms);
      final body = res.data;
      if (body is! List) return const [];
      return asJsonList(body)
          .map((e) => _mapVoiceRoom(asJsonMap(e)))
          .where((r) => r.id.isNotEmpty && r.slug.isNotEmpty)
          .toList();
    } on ApiException catch (e) {
      final code = e.statusCode;
      if (code == 404 || code == 401 || code == 403) return const [];
      rethrow;
    }
  }

  LiveStreamEntity _mapStreamRow(Map<String, dynamic> json) {
    final titleRaw = pick(json, ['title', 'name', 'description'])?.toString();
    final title = (titleRaw != null && titleRaw.trim().isNotEmpty)
        ? titleRaw.trim()
        : 'Canlı yayın';

    var thumb = pick(json, [
          'thumbnailUrl',
          'thumbnail',
          'coverUrl',
          'imageUrl',
          'broadcastImage',
          'backgroundUrl',
        ])
        as String?;
    thumb = _absoluteSiteUrl(thumb);

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

  VoiceRoomEntity _mapVoiceRoom(Map<String, dynamic> json) {
    final o = pick(json, ['owner']);
    String? ownerName;
    if (o is Map) {
      final om = asJsonMap(o);
      ownerName = pick(om, ['name', 'username', 'displayName'])?.toString();
    }
    var bg = pick(json, ['backgroundImage', 'backgroundUrl', 'coverImage'])
        as String?;
    bg = _absoluteSiteUrl(bg);
    return VoiceRoomEntity(
      id: pick(json, ['id'])?.toString() ?? '',
      slug: pick(json, ['slug'])?.toString() ?? '',
      nameTr: pick(json, ['nameTr', 'nameEn', 'name', 'slug'])?.toString() ?? 'Oda',
      descTr: pick(json, ['descTr', 'descEn', 'description']) as String?,
      icon: pick(json, ['icon']) as String?,
      onlineCount: asInt(pick(json, ['onlineCount', 'userCount', 'listeners'])),
      backgroundImageUrl: bg,
      ownerName: ownerName,
    );
  }

  /// Site göreli görsel yollarını (`/uploads/...`) tam HTTPS URL yapar.
  static String? _absoluteSiteUrl(String? u) {
    if (u == null || u.isEmpty) return u;
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('//')) return 'https:$u';
    if (u.startsWith('/')) {
      final o = Env.siteOrigin.replaceAll(RegExp(r'/+$'), '');
      return '$o$u';
    }
    return u;
  }
}
