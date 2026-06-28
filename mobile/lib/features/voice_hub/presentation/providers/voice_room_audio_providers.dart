import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../agora/presentation/providers/agora_providers.dart';
import '../audio/voice_room_audio_coordinator.dart';
import 'chat_room_providers.dart';

final voiceRoomAudioCoordinatorProvider = Provider<VoiceRoomAudioCoordinator>((ref) {
  final coord = VoiceRoomAudioCoordinator(
    remote: ref.watch(chatRoomRemoteProvider),
    agoraToken: ref.watch(agoraRemoteProvider),
  );
  ref.onDispose(coord.dispose);
  return coord;
});
