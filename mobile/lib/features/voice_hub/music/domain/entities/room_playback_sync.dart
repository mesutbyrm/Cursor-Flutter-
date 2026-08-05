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
    this.elapsedSeconds,
    this.embedUrl,
  });

  final String? currentVideoId;
  final int currentPositionMs;
  final bool isPlaying;
  final int? trackStartedAtMs;
  final String? streamUrl;
  /// SSE `elapsedSeconds` — odaya geç katılan için başlangıç saniyesi.
  final double? elapsedSeconds;
  final String? embedUrl;

  int resolvedPositionMs({DateTime? now}) {
    if (elapsedSeconds != null && elapsedSeconds! >= 0) {
      return VoicePlaybackLimits.clampPositionMs(
        (elapsedSeconds! * 1000).round(),
      );
    }
    if (!isPlaying || trackStartedAtMs == null) {
      return VoicePlaybackLimits.clampPositionMs(currentPositionMs);
    }
    final t = now ?? DateTime.now();
    final raw = currentPositionMs +
        (t.millisecondsSinceEpoch - trackStartedAtMs!).clamp(0, 1 << 30);
    return VoicePlaybackLimits.clampPositionMs(raw);
  }

  double resolvedStartSeconds({DateTime? now}) {
    if (elapsedSeconds != null && elapsedSeconds! >= 0) {
      return elapsedSeconds!.clamp(0, 86400);
    }
    return resolvedPositionMs(now: now) / 1000.0;
  }

  factory RoomPlaybackSync.fromPayload(Map<String, dynamic> map) {
    final flat = unwrapVoiceSseDjPayload(map);
    final pos = flat['currentPosition'] ?? flat['positionMs'];
    final started = flat['startedAt'] ?? flat['startedAtMs'];
    final elapsedRaw = flat['elapsedSeconds'];
    final np = flat['nowPlaying'];
    String? videoId = flat['currentVideoId']?.toString() ??
        flat['videoId']?.toString();
    if ((videoId == null || videoId.isEmpty) && np is Map) {
      videoId = np['videoId']?.toString();
    }
    final embed =
        flat['embedUrl']?.toString() ?? (np is Map ? np['embedUrl']?.toString() : null);
    double? elapsed;
    if (elapsedRaw is num) {
      elapsed = elapsedRaw.toDouble();
    } else if (elapsedRaw is String) {
      elapsed = double.tryParse(elapsedRaw.trim());
    }
    return RoomPlaybackSync(
      currentVideoId: videoId,
      currentPositionMs: pos is num ? pos.round() : 0,
      isPlaying: voiceSseDjIsPlaying(flat),
      trackStartedAtMs: voiceSseTrackStartedAtMs(started),
      streamUrl: flat['musicUrl']?.toString() ??
          flat['streamUrl']?.toString() ??
          flat['videoUrl']?.toString() ??
          flat['youtubeUrl']?.toString(),
      elapsedSeconds: elapsed,
      embedUrl: embed,
    );
  }

  @override
  List<Object?> get props => [
        currentVideoId,
        currentPositionMs,
        isPlaying,
        trackStartedAtMs,
        streamUrl,
        elapsedSeconds,
        embedUrl,
      ];
}
