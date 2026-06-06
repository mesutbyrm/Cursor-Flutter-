import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/platform_stats_entity.dart';

/// Canlı site istatistikleri — birden fazla uç dener.
class PlatformStatsRemoteDataSource {
  PlatformStatsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PlatformStatsEntity?> fetch() async {
    for (final path in const [
      '/api/platform-stats',
      '/api/public-stats',
      ApiEndpoints.socialPublicStats,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final parsed = _parseBody(res.data);
        if (parsed != null) return parsed;
      } catch (_) {}
    }
    return null;
  }

  Map<String, dynamic>? _unwrap(dynamic body) {
    if (body is Map) {
      final m = asJsonMap(body);
      final data = m['data'];
      if (data is Map) return asJsonMap(data);
      return m;
    }
    return null;
  }

  PlatformStatsEntity? _parseBody(dynamic body) {
    final root = _unwrap(body);
    if (root == null) return null;

    int pickInt(List<String> keys, [int fallback = 0]) {
      for (final k in keys) {
        final v = root[k];
        if (v is num) return v.toInt();
        if (v is Map) {
          final t = pick(asJsonMap(v), ['total', 'count', 'online']);
          if (t is num) return t.toInt();
        }
      }
      return fallback;
    }

    var online = pickInt(['onlineUsers', 'online', 'totalOnline']);
    if (online <= 0) {
      final users = root['users'];
      if (users is Map) {
        online = pickInt(['online'], 0);
        if (online <= 0) online = asInt(pick(asJsonMap(users), ['total']));
      }
      final chat = root['chat'];
      if (online <= 0 && chat is Map) {
        online = asInt(pick(asJsonMap(chat), ['totalOnline', 'online']));
      }
    }

    final recent = _parseRecent(root['recentLogins'] ?? root['recent']);

    return PlatformStatsEntity(
      onlineUsers: online,
      inGames: pickInt(['inGames', 'games', 'playing']),
      inSocial: pickInt(['inSocial', 'social']),
      onLive: pickInt(['onLive', 'live', 'activeStreams']),
      inVoiceChat: pickInt(['inVoiceChat', 'voice', 'voiceChat']),
      fortuneActive: pickInt(['fortuneActive', 'fortunes', 'fortune']),
      browsing: pickInt(['browsing', 'wandering', 'visitors']),
      todayLogins: pickInt(['todayLogins', 'loginsToday', 'today']),
      recentLogins: recent,
    );
  }

  List<RecentLoginEntity> _parseRecent(dynamic raw) {
    if (raw is! List) return const [];
    final out = <RecentLoginEntity>[];
    for (final item in raw.take(5)) {
      if (item is! Map) continue;
      final m = asJsonMap(item);
      final userJson = m['user'] is Map ? asJsonMap(m['user']) : m;
      final id = pick(userJson, ['id', 'userId', 'cuid'])?.toString() ?? '';
      if (id.isEmpty) continue;
      final username =
          pick(userJson, ['username', 'userName'])?.toString() ?? id;
      out.add(
        RecentLoginEntity(
          user: UserEntity(
            id: id,
            username: username,
            displayName: pick(userJson, ['displayName', 'name'])?.toString(),
            avatarUrl: pick(userJson, ['avatarUrl', 'avatar', 'image'])
                ?.toString(),
          ),
          timeLabel: pick(m, ['timeLabel', 'timeAgo', 'ago'])?.toString() ??
              'Az önce',
          activityLabel:
              pick(m, ['activityLabel', 'activity', 'fortuneType'])
                      ?.toString() ??
                  'Çevrimiçi',
          activityEmoji:
              pick(m, ['activityEmoji', 'emoji'])?.toString() ?? '✋',
          verified: asBool(pick(userJson, ['verified', 'isVerified'])),
        ),
      );
    }
    return out;
  }
}
