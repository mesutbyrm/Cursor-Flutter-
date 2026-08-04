import 'package:equatable/equatable.dart';

/// Sunucu `current-song` / SSE `song_*` yanıtı.
class RoomSongDto extends Equatable {
  const RoomSongDto({
    this.queueId,
    this.videoId,
    this.title,
    this.thumbnail,
    this.durationSec,
    this.channel,
    this.ownerId,
    this.ownerName,
    this.startedAtMs,
    this.paused = false,
    this.pausedAtMs,
    this.elapsedMs = 0,
    this.serverTimeMs,
  });

  final String? queueId;
  final String? videoId;
  final String? title;
  final String? thumbnail;
  final int? durationSec;
  final String? channel;
  final String? ownerId;
  final String? ownerName;
  final int? startedAtMs;
  final bool paused;
  final int? pausedAtMs;
  final int elapsedMs;
  final int? serverTimeMs;

  bool get hasTrack => videoId != null && videoId!.isNotEmpty;

  double resolvedElapsedSeconds({DateTime? now}) {
    final t = now ?? DateTime.now();
    if (paused) return elapsedMs / 1000.0;
    if (startedAtMs != null) {
      final delta = t.millisecondsSinceEpoch - startedAtMs!;
      return (elapsedMs + delta.clamp(0, 86400000)) / 1000.0;
    }
    return elapsedMs / 1000.0;
  }

  factory RoomSongDto.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    String? ownerId;
    String? ownerName;
    if (owner is Map) {
      ownerId = owner['id']?.toString();
      ownerName = owner['name']?.toString();
    }
    ownerId ??= json['ownerId']?.toString();
    ownerName ??= json['ownerName']?.toString();

    int? startedAt;
    final startedRaw = json['startedAt'];
    if (startedRaw is num) {
      startedAt = startedRaw.round();
    } else if (startedRaw is String) {
      startedAt = DateTime.tryParse(startedRaw)?.millisecondsSinceEpoch;
    }

    return RoomSongDto(
      queueId: json['queueId']?.toString(),
      videoId: json['videoId']?.toString(),
      title: json['title']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      durationSec: _int(json['duration'] ?? json['durationSec']),
      channel: json['channel']?.toString(),
      ownerId: ownerId,
      ownerName: ownerName,
      startedAtMs: startedAt,
      paused: json['paused'] == true,
      pausedAtMs: _int(json['pausedAt']),
      elapsedMs: _int(json['elapsedMs']) ?? 0,
      serverTimeMs: _int(json['serverTime']),
    );
  }

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  @override
  List<Object?> get props => [
        queueId,
        videoId,
        title,
        paused,
        elapsedMs,
        serverTimeMs,
      ];
}

class RoomSongQueueItemDto extends Equatable {
  const RoomSongQueueItemDto({
    required this.queueId,
    required this.videoId,
    required this.title,
    this.thumbnail,
    this.duration,
    this.channel,
    this.ownerId,
    this.ownerName,
    this.position = 0,
  });

  final String queueId;
  final String videoId;
  final String title;
  final String? thumbnail;
  final String? duration;
  final String? channel;
  final String? ownerId;
  final String? ownerName;
  final int position;

  factory RoomSongQueueItemDto.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    return RoomSongQueueItemDto(
      queueId: (json['queueId'] ?? json['id'])?.toString() ?? '',
      videoId: json['videoId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Şarkı',
      thumbnail: json['thumbnail']?.toString(),
      duration: json['duration']?.toString(),
      channel: json['channel']?.toString(),
      ownerId: owner is Map ? owner['id']?.toString() : json['ownerId']?.toString(),
      ownerName: owner is Map ? owner['name']?.toString() : json['ownerName']?.toString(),
      position: RoomSongDto._int(json['position']) ?? 0,
    );
  }

  @override
  List<Object?> get props => [queueId, videoId, title];
}

class YoutubeSearchResultDto extends Equatable {
  const YoutubeSearchResultDto({
    required this.videoId,
    required this.title,
    this.thumbnail,
    this.duration,
    this.channel,
  });

  final String videoId;
  final String title;
  final String? thumbnail;
  final String? duration;
  final String? channel;

  factory YoutubeSearchResultDto.fromJson(Map<String, dynamic> json) {
    return YoutubeSearchResultDto(
      videoId: (json['videoId'] ?? json['id'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      thumbnail: (json['thumbnail'] ?? json['thumbUrl'])?.toString(),
      duration: json['duration']?.toString(),
      channel: (json['channel'] ?? json['channelTitle'] ?? json['uploader'])?.toString(),
    );
  }

  @override
  List<Object?> get props => [videoId, title];
}
