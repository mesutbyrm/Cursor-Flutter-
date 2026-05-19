import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/live_stream_entity.dart';

class LiveRemoteDataSource {
  LiveRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<LiveStreamEntity>> fetch({int page = 1}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.liveStreams,
      query: {'page': page, 'limit': 30},
    );
    final body = res.data;
    dynamic list;
    if (body is Map<String, dynamic>) {
      list = pick(body, ['items', 'data', 'streams', 'results', 'lives']);
    } else {
      list = body;
    }
    return asJsonList(list).map(_mapRow).toList();
  }

  LiveStreamEntity _mapRow(Map<String, dynamic> json) {
    return LiveStreamEntity(
      id: pick(json, ['id', '_id', 'streamId'])?.toString() ?? '',
      title: pick(json, ['title', 'name', 'description'])?.toString() ?? 'Yayın',
      streamerName: () {
        final u = pick(json, ['user', 'streamer', 'host']);
        if (u is Map) {
          final m = asJsonMap(u);
          return pick(m, ['displayName', 'username', 'name'])?.toString();
        }
        return pick(json, ['streamerName', 'hostName', 'username'])
            ?.toString();
      }(),
      thumbnailUrl: pick(json, [
        'thumbnailUrl',
        'thumbnail',
        'coverUrl',
        'imageUrl',
      ]) as String?,
      viewerCount: asInt(pick(json, ['viewerCount', 'viewers', 'watching'])),
      isLive: () {
        final v = pick(json, ['isLive', 'live']);
        if (v == true) return true;
        final s = pick(json, ['status'])?.toString().toLowerCase();
        return s == 'live' || s == 'started';
      }(),
    );
  }
}
