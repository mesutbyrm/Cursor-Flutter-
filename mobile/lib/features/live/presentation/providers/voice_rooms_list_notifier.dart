import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/voice_room_entity.dart';
import 'live_providers.dart';

/// Sesli oda listesi — tek kaynak (keşif + ana sayfa + oda arama).
class VoiceRoomsListNotifier extends AsyncNotifier<List<VoiceRoomEntity>> {
  @override
  Future<List<VoiceRoomEntity>> build() async {
    ref.keepAlive();
    return ref.read(liveRepositoryProvider).fetchVoiceRooms();
  }

  Future<void> refresh() async {
    final previous = state;
    state = const AsyncValue<List<VoiceRoomEntity>>.loading()
        .copyWithPrevious(previous);
    state = await AsyncValue.guard(
      () => ref.read(liveRepositoryProvider).fetchVoiceRooms(),
    );
  }
}

final voiceRoomsListNotifierProvider =
    AsyncNotifierProvider<VoiceRoomsListNotifier, List<VoiceRoomEntity>>(
  VoiceRoomsListNotifier.new,
);
