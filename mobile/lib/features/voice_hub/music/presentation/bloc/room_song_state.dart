import 'package:equatable/equatable.dart';

import '../../data/dto/room_song_dto.dart';

class RoomSongState extends Equatable {
  const RoomSongState({
    this.current,
    this.queue = const [],
    this.serverTimeMs,
    this.localDriftMs = 0,
    this.miniExpanded = true,
    this.fullscreen = false,
    this.loading = false,
    this.canControl = false,
    this.roomId,
  });

  final RoomSongDto? current;
  final List<RoomSongQueueItemDto> queue;
  final int? serverTimeMs;
  final int localDriftMs;
  final bool miniExpanded;
  final bool fullscreen;
  final bool loading;
  final bool canControl;
  final String? roomId;

  bool get hasTrack => current?.hasTrack == true;

  double get progress {
    final c = current;
    if (c == null || !c.hasTrack) return 0;
    final dur = c.durationSec ?? 0;
    if (dur <= 0) return 0;
    final elapsed = c.resolvedElapsedSeconds();
    return (elapsed / dur).clamp(0.0, 1.0);
  }

  RoomSongState copyWith({
    RoomSongDto? current,
    bool clearCurrent = false,
    List<RoomSongQueueItemDto>? queue,
    int? serverTimeMs,
    int? localDriftMs,
    bool? miniExpanded,
    bool? fullscreen,
    bool? loading,
    bool? canControl,
    String? roomId,
  }) {
    return RoomSongState(
      current: clearCurrent ? null : (current ?? this.current),
      queue: queue ?? this.queue,
      serverTimeMs: serverTimeMs ?? this.serverTimeMs,
      localDriftMs: localDriftMs ?? this.localDriftMs,
      miniExpanded: miniExpanded ?? this.miniExpanded,
      fullscreen: fullscreen ?? this.fullscreen,
      loading: loading ?? this.loading,
      canControl: canControl ?? this.canControl,
      roomId: roomId ?? this.roomId,
    );
  }

  @override
  List<Object?> get props => [
        current,
        queue,
        serverTimeMs,
        localDriftMs,
        miniExpanded,
        fullscreen,
        loading,
        canControl,
        roomId,
      ];
}
