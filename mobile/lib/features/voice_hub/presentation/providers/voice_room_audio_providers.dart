import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../audio/voice_room_audio_coordinator.dart';
import '../audio/voice_trtc_engine.dart';
import 'chat_room_providers.dart';

final voiceRoomAudioCoordinatorProvider = Provider<VoiceRoomAudioCoordinator>((ref) {
  final coord = VoiceRoomAudioCoordinator(
    remote: ref.watch(chatRoomRemoteProvider),
    trtc: VoiceTrtcEngine(tokenSource: ref.watch(trtcRemoteProvider)),
  );
  ref.onDispose(coord.dispose);
  return coord;
});
