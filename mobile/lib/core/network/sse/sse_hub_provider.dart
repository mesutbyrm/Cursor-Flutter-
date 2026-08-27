import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/live/presentation/gifts/providers/live_gift_providers.dart';
import '../../../features/voice_hub/data/services/chat_room_sse_service.dart';
import '../../../features/live/data/services/video_stream_sse_service.dart';
import 'sse_connection_hub.dart';
import 'sse_hub_lifecycle.dart';

export 'sse_hub_lifecycle.dart';

/// Uygulama genelinde tek SSE hub — sayfa geçişlerinde bağlantı paylaşımı.
final sseConnectionHubProvider = Provider<SseConnectionHub>((ref) {
  ref.keepAlive();
  final hub = SseConnectionHub(giftsRemote: ref.watch(liveGiftsRemoteProvider));
  ref.onDispose(hub.dispose);
  return hub;
});

final sseHubLifecycleProvider = Provider<SseHubLifecycleBinding>((ref) {
  final binding = SseHubLifecycleBinding(ref.read(sseConnectionHubProvider));
  ref.onDispose(binding.dispose);
  return binding;
});

/// Oda başına paylaşımlı sesli oda SSE servisi.
final voiceRoomSseForProvider =
    Provider.family<ChatRoomSseService, String>((ref, roomId) {
  return ref.watch(sseConnectionHubProvider).voiceRoom(roomId);
});

/// Yayın başına paylaşımlı video SSE servisi.
final videoStreamSseForProvider =
    Provider.family<VideoStreamSseService, String>((ref, streamId) {
  return ref.watch(sseConnectionHubProvider).videoStream(streamId);
});
