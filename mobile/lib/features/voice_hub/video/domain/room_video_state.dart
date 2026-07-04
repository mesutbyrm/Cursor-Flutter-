import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../music/domain/entities/room_playback_sync.dart';
import 'youtube_video_id.dart';

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
    this.isDismissing = false,
    this.audioOnly = false,
  });

  final String? videoId;
  final String? title;
  final String? thumbUrl;
  final bool isPlaying;
  final int positionMs;
  final int? trackStartedAtMs;
  final MusicQueueItem? nowPlaying;
  final bool isDismissing;

  /// Ses-only müzik — YouTube IFrame gizli (1x1) çalar, video gösterilmez.
  final bool audioOnly;

  bool get hasActiveVideo => YoutubeVideoId.isValid(videoId);

  /// Görünür video şeridi yalnızca video isteğinde gösterilir.
  bool get showsVideo => hasActiveVideo && !audioOnly;

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
    bool? isDismissing,
    bool? audioOnly,
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
      isDismissing: isDismissing ?? this.isDismissing,
      audioOnly: audioOnly ?? this.audioOnly,
    );
  }

  static RoomVideoState fromDjAndSync({
    required ChatRoomDjState dj,
    RoomPlaybackSync? sync,
  }) {
    final np = dj.nowPlaying;
    // Video isteği görünür şerit; diğer YouTube müzik ses-only (gizli iframe).
    if (np == null) {
      return const RoomVideoState();
    }
    final videoId = YoutubeVideoId.fromDj(
      currentVideoId: sync?.currentVideoId ?? np.resolvedVideoId,
      nowPlayingUrl: np.youtubeUrl,
    );
    if (videoId == null) {
      return const RoomVideoState();
    }
    final playing = sync?.isPlaying ?? dj.playing;
    return RoomVideoState(
      videoId: videoId,
      title: np.title,
      thumbUrl: np.thumbUrl,
      isPlaying: playing,
      positionMs: sync?.currentPositionMs ?? 0,
      trackStartedAtMs: sync?.trackStartedAtMs,
      nowPlaying: np,
      // Sesli odada müzik yalnızca arka planda ÇALAR — video/görüntü gösterilmez.
      // (Kullanıcı isteği: "müzik arka planda çalsın, video gelmesin".)
      audioOnly: true,
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
        isDismissing,
        audioOnly,
      ];
}
