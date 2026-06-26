import 'package:equatable/equatable.dart';

import '../../../domain/voice_playback_limits.dart';
import '../../../presentation/utils/voice_sse_dj_payload.dart';

/// Sunucu otoriteli oda müziği senkron durumu (SSE / Socket).
class RoomPlaybackSync extends Equatable {
  const RoomPlaybackSync({
    this.currentVideoId,
    this.currentPositionMs = 0,
    this.isPlaying = false,
    this.trackStartedAtMs,
    this.streamUrl,
  });

  final String? currentVideoId;
  final int currentPositionMs;
  final bool isPlaying;
  final int? trackStartedAtMs;
  final String? streamUrl;

  int resolvedPositionMs({DateTime? now}) {
    if (!isPlaying || trackStartedAtMs == null) {
      return VoicePlaybackLimits.clampPositionMs(currentPositionMs);
    }
    final t = now ?? DateTime.now();
    final raw = currentPositionMs +
        (t.millisecondsSinceEpoch - trackStartedAtMs!).clamp(0, 1 << 30);
    return VoicePlaybackLimits.clampPositionMs(raw);
  }

  factory RoomPlaybackSync.fromPayload(Map<String, dynamic> map) {
    final flat = unwrapVoiceSseDjPayload(map);
    final pos = flat['currentPosition'] ?? flat['positionMs'];
    final started = flat['trackStartedAt'] ?? flat['startedAt'];
    final np = flat['nowPlaying'];
    String? videoId = flat['currentVideoId']?.toString() ??
        flat['videoId']?.toString();
    if ((videoId == null || videoId.isEmpty) && np is Map) {
      videoId = np['videoId']?.toString();
    }
    return RoomPlaybackSync(
      currentVideoId: videoId,
      currentPositionMs: pos is num ? pos.round() : 0,
      isPlaying: voiceSseDjIsPlaying(flat),
      trackStartedAtMs: voiceSseTrackStartedAtMs(started),
      streamUrl: flat['musicUrl']?.toString() ?? flat['streamUrl']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        currentVideoId,
        currentPositionMs,
        isPlaying,
        trackStartedAtMs,
        streamUrl,
      ];
}
