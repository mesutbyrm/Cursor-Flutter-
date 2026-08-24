import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../music/data/datasources/room_music_remote_datasource.dart';
import '../audio/voice_room_audio_coordinator.dart';
import '../audio/voice_room_trtc_music_mixer.dart';
import '../audio/voice_trtc_engine.dart';
import 'chat_room_providers.dart';

final roomMusicRemoteProvider = Provider<RoomMusicRemoteDataSource>((ref) {
  return RoomMusicRemoteDataSource(ref.watch(dioProvider));
});

final voiceRoomTrtcMusicMixerProvider = Provider<VoiceRoomTrtcMusicMixer>((ref) {
  final mixer = VoiceRoomTrtcMusicMixer();
  ref.onDispose(mixer.dispose);
  return mixer;
});

final voiceRoomAudioCoordinatorProvider = Provider<VoiceRoomAudioCoordinator>((ref) {
  final coord = VoiceRoomAudioCoordinator(
    remote: ref.watch(chatRoomRemoteProvider),
    trtc: VoiceTrtcEngine(tokenSource: ref.watch(trtcRemoteProvider)),
  );
  ref.onDispose(coord.dispose);
  return coord;
});
