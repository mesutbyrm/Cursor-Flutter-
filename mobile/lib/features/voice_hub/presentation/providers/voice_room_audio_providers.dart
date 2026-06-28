import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/voice_room_audio_coordinator.dart';
import 'chat_room_providers.dart';

final voiceRoomAudioCoordinatorProvider = Provider<VoiceRoomAudioCoordinator>((ref) {
  final coord = VoiceRoomAudioCoordinator(
    remote: ref.watch(chatRoomRemoteProvider),
  );
  ref.onDispose(coord.dispose);
  return coord;
});
