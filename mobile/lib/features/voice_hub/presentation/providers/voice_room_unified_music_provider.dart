import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../music/presentation/providers/room_song_state_provider.dart';
import '../utils/voice_room_unified_music.dart';
import 'chat_room_providers.dart';

/// DJ + RoomSongBloc birleşik müzik görünümü.
final voiceRoomUnifiedMusicProvider = Provider.autoDispose
    .family<VoiceRoomUnifiedMusic, String>((ref, liveKey) {
  final key = liveKey.trim();
  if (key.isEmpty) {
    return const VoiceRoomUnifiedMusic(
      nowPlaying: null,
      queue: const [],
      waiting: const [],
      source: VoiceRoomMusicSource.dj,
    );
  }
  final dj = ref.watch(voiceRoomLiveProvider(key).select((s) => s.dj));
  final songAsync = ref.watch(roomSongStateProvider(key));
  final songState = songAsync.valueOrNull;
  return VoiceRoomUnifiedMusic.resolve(dj: dj, songState: songState);
});
