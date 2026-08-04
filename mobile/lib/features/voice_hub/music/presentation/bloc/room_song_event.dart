import 'package:equatable/equatable.dart';

import '../../data/dto/room_song_dto.dart';

sealed class RoomSongEvent extends Equatable {
  const RoomSongEvent();
  @override
  List<Object?> get props => [];
}

class RoomSongStarted extends RoomSongEvent {
  const RoomSongStarted(this.song, {this.elapsedSeconds});
  final RoomSongDto song;
  final double? elapsedSeconds;
  @override
  List<Object?> get props => [song, elapsedSeconds];
}

class RoomSongPaused extends RoomSongEvent {
  const RoomSongPaused(this.song);
  final RoomSongDto song;
  @override
  List<Object?> get props => [song];
}

class RoomSongResumed extends RoomSongEvent {
  const RoomSongResumed(this.song);
  final RoomSongDto song;
  @override
  List<Object?> get props => [song];
}

class RoomSongFinished extends RoomSongEvent {
  const RoomSongFinished();
}

class RoomSongQueueUpdated extends RoomSongEvent {
  const RoomSongQueueUpdated(this.queue, {this.current});
  final List<RoomSongQueueItemDto> queue;
  final RoomSongDto? current;
  @override
  List<Object?> get props => [queue, current];
}

class RoomSongRemoved extends RoomSongEvent {
  const RoomSongRemoved(this.queueId, {this.queue = const [], this.current});
  final String queueId;
  final List<RoomSongQueueItemDto> queue;
  final RoomSongDto? current;
  @override
  List<Object?> get props => [queueId, queue, current];
}

class RoomSongJoinSync extends RoomSongEvent {
  const RoomSongJoinSync(this.roomId);
  final String roomId;
  @override
  List<Object?> get props => [roomId];
}

class RoomSongSeekTick extends RoomSongEvent {
  const RoomSongSeekTick(this.nowMs);
  final int nowMs;
  @override
  List<Object?> get props => [nowMs];
}

class RoomSongMiniExpanded extends RoomSongEvent {
  const RoomSongMiniExpanded(this.expanded);
  final bool expanded;
  @override
  List<Object?> get props => [expanded];
}

class RoomSongFullscreen extends RoomSongEvent {
  const RoomSongFullscreen(this.fullscreen);
  final bool fullscreen;
  @override
  List<Object?> get props => [fullscreen];
}

class RoomSongUserPause extends RoomSongEvent {
  const RoomSongUserPause();
}

class RoomSongUserResume extends RoomSongEvent {
  const RoomSongUserResume();
}

class RoomSongUserSkip extends RoomSongEvent {
  const RoomSongUserSkip();
}
