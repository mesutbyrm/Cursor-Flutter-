import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/room_access_models.dart';

/// Oda sahibine gelen "odaya giriş isteği" (SSE `join_request` veya açılışta
/// sunucudan çekilen bekleyen istekler).
class VoiceRoomJoinRequestEntry {
  const VoiceRoomJoinRequestEntry({
    required this.roomKey,
    required this.request,
  });

  final String roomKey;
  final PendingJoinRequest request;

  String get dedupKey => '${roomKey.trim()}:${request.id}';
}

class VoiceRoomJoinRequestQueue extends Notifier<List<VoiceRoomJoinRequestEntry>> {
  @override
  List<VoiceRoomJoinRequestEntry> build() => const [];

  void enqueue(VoiceRoomJoinRequestEntry entry) {
    if (entry.roomKey.isEmpty || entry.request.id.isEmpty) return;
    if (state.any((e) => e.dedupKey == entry.dedupKey)) return;
    state = [...state, entry];
  }

  /// Başka bir yönetici yanıtladı / istek çözüldü: popup kuyruğundan düş.
  void resolve(String roomKey, String requestId) {
    final key = '${roomKey.trim()}:$requestId';
    state = state.where((e) => e.dedupKey != key).toList(growable: false);
  }

  void remove(String dedupKey) {
    state = state.where((e) => e.dedupKey != dedupKey).toList(growable: false);
  }
}

final voiceRoomJoinRequestQueueProvider =
    NotifierProvider<VoiceRoomJoinRequestQueue, List<VoiceRoomJoinRequestEntry>>(
  VoiceRoomJoinRequestQueue.new,
);

/// Kuyruk değişince dinleyiciyi uyandırmak için sinyal.
class VoiceJoinRequestSignalNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final voiceJoinRequestSignalProvider =
    NotifierProvider<VoiceJoinRequestSignalNotifier, int>(
  VoiceJoinRequestSignalNotifier.new,
);
