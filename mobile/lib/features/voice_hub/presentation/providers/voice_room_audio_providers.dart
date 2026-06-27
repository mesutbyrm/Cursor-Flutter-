import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_room_providers.dart';

final voiceRoomAudioCoordinatorProvider = Provider<VoiceRoomAudioCoordinator>((ref) {
  final coord = VoiceRoomAudioCoordinator(
    remote: ref.watch(chatRoomRemoteProvider),
  );
  ref.onDispose(coord.dispose);
  return coord;
});
