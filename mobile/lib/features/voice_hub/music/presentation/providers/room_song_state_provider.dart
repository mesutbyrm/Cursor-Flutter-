import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bloc/room_song_state.dart';
import 'room_music_providers.dart';

/// RoomSongBloc state — UI yeniden çizimi için stream.
final roomSongStateProvider =
    StreamProvider.autoDispose.family<RoomSongState, String>((ref, roomId) {
  final id = roomId.trim();
  if (id.isEmpty) {
    return Stream.value(const RoomSongState());
  }
  final bloc = ref.watch(roomSongBlocProvider(id));
  return bloc.stream;
});
