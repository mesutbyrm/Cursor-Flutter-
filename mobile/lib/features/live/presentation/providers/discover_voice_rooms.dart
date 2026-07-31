import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/voice_room_entity.dart';
import 'voice_rooms_list_notifier.dart';

/// Sesli oda keşif listesi — tek kaynak (`voiceRoomsListNotifierProvider`).
void invalidateDiscoverVoiceRooms(Ref ref) {
  ref.invalidate(voiceRoomsListNotifierProvider);
}

/// Geriye dönük: keşif listesi (çift fetch önlenir).
final voiceRoomsProvider = FutureProvider<List<VoiceRoomEntity>>((ref) async {
  final cached = ref.watch(voiceRoomsListNotifierProvider).valueOrNull;
  if (cached != null) return cached;
  return ref.read(voiceRoomsListNotifierProvider.future);
});
