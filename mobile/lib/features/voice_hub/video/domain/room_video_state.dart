import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../music/domain/entities/room_playback_sync.dart';

/// Tam ekran YouTube video müzik modu — oda senkron durumu.
class RoomVideoState extends Equatable {
  const RoomVideoState({
    this.videoId,
    this.title,
    this.thumbUrl,
    this.isPlaying = false,
    this.positionMs = 0,
    this.trackStartedAtMs,
    this.nowPlaying,
  });

  final String? videoId;
  final String? title;
  final String? thumbUrl;
  final bool isPlaying;
  final int positionMs;
  final int? trackStartedAtMs;
  final MusicQueueItem? nowPlaying;

  bool get hasActiveVideo =>
      videoId != null && videoId!.trim().isNotEmpty;

  int resolvedPositionMs({DateTime? now}) {
    if (!isPlaying || trackStartedAtMs == null) return positionMs;
    final t = now ?? DateTime.now();
    return positionMs +
        (t.millisecondsSinceEpoch - trackStartedAtMs!).clamp(0, 1 << 30);
  }

  RoomVideoState copyWith({
    String? videoId,
    bool clearVideoId = false,
    String? title,
    bool clearTitle = false,
    String? thumbUrl,
    bool clearThumbUrl = false,
    bool? isPlaying,
    int? positionMs,
    int? trackStartedAtMs,
    bool clearTrackStartedAt = false,
    MusicQueueItem? nowPlaying,
    bool clearNowPlaying = false,
  }) {
    return RoomVideoState(
      videoId: clearVideoId ? null : (videoId ?? this.videoId),
      title: clearTitle ? null : (title ?? this.title),
      thumbUrl: clearThumbUrl ? null : (thumbUrl ?? this.thumbUrl),
      isPlaying: isPlaying ?? this.isPlaying,
      positionMs: positionMs ?? this.positionMs,
      trackStartedAtMs: clearTrackStartedAt
          ? null
          : (trackStartedAtMs ?? this.trackStartedAtMs),
      nowPlaying: clearNowPlaying ? null : (nowPlaying ?? this.nowPlaying),
    );
  }

  static RoomVideoState fromDjAndSync({
    required ChatRoomDjState dj,
    RoomPlaybackSync? sync,
  }) {
    final videoId = sync?.currentVideoId ??
        ChatRoomDjState.videoIdFromLoose(
          dj.nowPlaying?.youtubeUrl ??
              dj.playbackResolveSeed ??
              dj.musicUrl ??
              '',
        );
    if (videoId == null || videoId.isEmpty) {
      return const RoomVideoState();
    }
    final np = dj.nowPlaying;
    return RoomVideoState(
      videoId: videoId,
      title: np?.title,
      thumbUrl: np?.thumbUrl,
      isPlaying: sync?.isPlaying ?? dj.playing,
      positionMs: sync?.currentPositionMs ?? 0,
      trackStartedAtMs: sync?.trackStartedAtMs,
      nowPlaying: np,
    );
  }

  @override
  List<Object?> get props => [
        videoId,
        title,
        thumbUrl,
        isPlaying,
        positionMs,
        trackStartedAtMs,
        nowPlaying?.id,
      ];
}
