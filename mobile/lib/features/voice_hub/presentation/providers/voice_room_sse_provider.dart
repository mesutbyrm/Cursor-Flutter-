import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/chat_room_sse_service.dart';

final voiceRoomSseServiceProvider = Provider<ChatRoomSseService>((ref) {
  final service = ChatRoomSseService();
  ref.onDispose(service.dispose);
  return service;
});

/// Geriye dönük alias.
final chatRoomSseServiceProvider = voiceRoomSseServiceProvider;
