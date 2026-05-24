import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../livekit/data/datasources/livekit_remote_datasource.dart';
import '../../../trtc/data/datasources/trtc_remote_datasource.dart';
import '../audio/voice_room_audio_coordinator.dart';

final liveKitRemoteProvider = Provider<LiveKitRemoteDataSource>((ref) {
  return LiveKitRemoteDataSource(ref.watch(dioProvider));
});

final voiceRoomAudioCoordinatorProvider = Provider<VoiceRoomAudioCoordinator>((ref) {
  final coord = VoiceRoomAudioCoordinator(
    liveKitRemote: ref.watch(liveKitRemoteProvider),
    trtcRemote: TrtcRemoteDataSource(ref.watch(dioProvider)),
  );
  ref.onDispose(coord.dispose);
  return coord;
});
