import '../../core/util/json_util.dart';

/// `GET /api/video-streams` yayın kartı.
class StreamSummary {
  const StreamSummary({
    required this.id,
    required this.title,
    this.streamerName,
    this.thumbnailUrl,
    this.category,
    this.viewerCount = 0,
    this.isLive = true,
    this.hostUserId,
    this.raw = const {},
  });

  final String id;
  final String title;
  final String? streamerName;
  final String? thumbnailUrl;
  final String? category;
  final int viewerCount;
  final bool isLive;
  final String? hostUserId;
  final Map<String, dynamic> raw;

  factory StreamSummary.fromJson(Map<String, dynamic> json) {
    final status = pick(json, ['status'])?.toString().toLowerCase();
    final endedAt = pick(json, ['endedAt', 'ended_at']);
    final isLiveFlag = pick(json, ['isLive']);
    var isLive = true;
    if (isLiveFlag is bool) {
      isLive = isLiveFlag;
    } else if (status == 'ended' || status == 'offline' || endedAt != null) {
      isLive = false;
    }

    String? hostUserId;
    String? streamerName;
    final u = pick(json, ['user', 'streamer', 'host']);
    if (u is Map) {
      final m = asJsonMap(u);
      hostUserId = pick(m, ['id', 'userId'])?.toString();
      streamerName =
          pick(m, ['displayName', 'username', 'name'])?.toString();
    }
    streamerName ??=
        pick(json, ['streamerName', 'hostName', 'username'])?.toString();
    hostUserId ??=
        pick(json, ['userId', 'hostUserId', 'streamerId'])?.toString();

    return StreamSummary(
      id: pick(json, ['id', '_id', 'streamId'])?.toString() ?? '',
      title: pick(json, ['title', 'name', 'description'])?.toString() ??
          'Canlı yayın',
      streamerName: streamerName,
      thumbnailUrl: pick(json, [
        'thumbnailUrl',
        'thumbnail',
        'coverUrl',
        'imageUrl',
        'broadcastImage',
        'backgroundUrl',
      ])?.toString(),
      category: pick(json, ['category', 'tag', 'type'])?.toString(),
      viewerCount: asInt(
        pick(json, ['viewerCount', 'viewers', 'watching']),
      ),
      isLive: isLive,
      hostUserId: hostUserId,
      raw: json,
    );
  }
}
