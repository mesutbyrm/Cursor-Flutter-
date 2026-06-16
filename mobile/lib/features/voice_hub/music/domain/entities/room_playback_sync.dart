import 'package:equatable/equatable.dart';

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
    if (!isPlaying || trackStartedAtMs == null) return currentPositionMs;
    final t = now ?? DateTime.now();
    return currentPositionMs +
        (t.millisecondsSinceEpoch - trackStartedAtMs!).clamp(0, 1 << 30);
  }

  factory RoomPlaybackSync.fromPayload(Map<String, dynamic> map) {
    final pos = map['currentPosition'] ?? map['positionMs'];
    final started = map['trackStartedAt'];
    return RoomPlaybackSync(
      currentVideoId: map['currentVideoId']?.toString(),
      currentPositionMs: pos is num ? pos.round() : 0,
      isPlaying: map['isPlaying'] == true || map['playing'] == true,
      trackStartedAtMs: started is num ? started.round() : null,
      streamUrl: map['musicUrl']?.toString() ?? map['streamUrl']?.toString(),
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
