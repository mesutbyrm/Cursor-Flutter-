import 'package:equatable/equatable.dart';

import '../../domain/song_playback_fields.dart';

/// Sunucu `current-song` / SSE `song_*` yanıtı.
class RoomSongDto extends Equatable {
  const RoomSongDto({
    this.queueId,
    this.videoId,
    this.musicUrl,
    this.youtubeUrl,
    this.videoUrl,
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
    this.playMode,
    this.isVideoRequest = false,
  });

  final String? queueId;
  final String? videoId;
  final String? musicUrl;
  final String? youtubeUrl;
  final String? videoUrl;
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
  final String? playMode;
  final bool isVideoRequest;

  bool get hasTrack {
    if (videoId != null && videoId!.isNotEmpty) return true;
    if (musicUrl != null && musicUrl!.isNotEmpty) return true;
    if (youtubeUrl != null && youtubeUrl!.isNotEmpty) return true;
    if (videoUrl != null && videoUrl!.isNotEmpty) return true;
    return false;
  }

  /// Mini player / IFrame için çözümlenmiş YouTube kimliği.
  String? get resolvedVideoId {
    final direct = videoId?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    return SongPlaybackFields.parseQuiet({
      if (musicUrl != null) 'musicUrl': musicUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (youtubeUrl != null) 'youtubeUrl': youtubeUrl,
    }).videoId;
  }

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
    final fields = SongPlaybackFields.fromJson(json);
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
      videoId: fields.videoId,
      musicUrl: fields.musicUrl,
      youtubeUrl: fields.youtubeUrl,
      videoUrl: fields.videoUrl,
      title: fields.title ?? json['title']?.toString(),
      thumbnail: fields.thumbnail,
      durationSec: _int(json['duration'] ?? json['durationSec']),
      channel: json['channel']?.toString(),
      ownerId: ownerId,
      ownerName: ownerName,
      startedAtMs: startedAt,
      paused: json['paused'] == true,
      pausedAtMs: _int(json['pausedAt']),
      elapsedMs: _int(json['elapsedMs']) ?? 0,
      serverTimeMs: _int(json['serverTime']),
      playMode: fields.playMode,
      isVideoRequest: fields.isVideoRequest,
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
        musicUrl,
        youtubeUrl,
        paused,
        elapsedMs,
        serverTimeMs,
        isVideoRequest,
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
    this.musicUrl,
    this.youtubeUrl,
    this.playMode,
    this.isVideoRequest = false,
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
  final String? musicUrl;
  final String? youtubeUrl;
  final String? playMode;
  final bool isVideoRequest;

  factory RoomSongQueueItemDto.fromJson(Map<String, dynamic> json) {
    final fields = SongPlaybackFields.fromJson(json);
    final owner = json['owner'];
    return RoomSongQueueItemDto(
      queueId: (json['queueId'] ?? json['id'])?.toString() ?? '',
      videoId: fields.videoId ?? '',
      title: fields.title ?? json['title']?.toString() ?? 'Şarkı',
      thumbnail: fields.thumbnail,
      duration: fields.duration ?? json['duration']?.toString(),
      channel: json['channel']?.toString(),
      ownerId:
          owner is Map ? owner['id']?.toString() : json['ownerId']?.toString(),
      ownerName: owner is Map
          ? owner['name']?.toString()
          : json['ownerName']?.toString(),
      position: RoomSongDto._int(json['position']) ?? 0,
      musicUrl: fields.musicUrl,
      youtubeUrl: fields.youtubeUrl,
      playMode: fields.playMode,
      isVideoRequest: fields.isVideoRequest,
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
    final fields = SongPlaybackFields.fromJson(json);
    return YoutubeSearchResultDto(
      videoId: fields.videoId ?? (json['videoId'] ?? json['id'])?.toString() ?? '',
      title: fields.title ?? json['title']?.toString() ?? '',
      thumbnail: (json['thumbnail'] ?? json['thumbUrl'])?.toString(),
      duration: fields.duration ?? json['duration']?.toString(),
      channel: (json['channel'] ?? json['channelTitle'] ?? json['uploader'])
          ?.toString(),
    );
  }

  @override
  List<Object?> get props => [videoId, title];
}
