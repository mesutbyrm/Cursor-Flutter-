import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../live/data/datasources/live_gifts_remote_datasource.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../data/datasources/chat_room_gifts_remote_datasource.dart';
import '../../data/services/voice_room_gift_realtime_service.dart';
final voiceRoomGiftRealtimeProvider =
    Provider<VoiceRoomGiftRealtimeService>((ref) {
  final dio = ref.watch(dioProvider);
  final live = LiveGiftsRemoteDataSource(dio);
  final gifts = ChatRoomGiftsRemoteDataSource(
    dio,
    live,
  );
  final service = VoiceRoomGiftRealtimeService(gifts);
  ref.onDispose(service.dispose);
  return service;
});

/// Uçan hediye kuyruğu — odada gösterilecek olaylar.
class VoiceGiftFlightQueue extends Notifier<List<LiveGiftEvent>> {
  @override
  List<LiveGiftEvent> build() => const [];

  void enqueue(LiveGiftEvent event) {
    state = [...state, event];
    if (state.length > 24) {
      state = state.sublist(state.length - 24);
    }
  }

  void dequeue(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void clear() => state = const [];
}

final voiceGiftFlightQueueProvider =
    NotifierProvider<VoiceGiftFlightQueue, List<LiveGiftEvent>>(
  VoiceGiftFlightQueue.new,
);
