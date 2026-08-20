import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/speak_request_status.dart';

/// Konuşma isteği SSE sinyali — host popup dinleyicisini uyandırır.
class VoiceSpeakRequestSignalNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final voiceSpeakRequestSignalProvider =
    NotifierProvider<VoiceSpeakRequestSignalNotifier, int>(
  VoiceSpeakRequestSignalNotifier.new,
);

class VoiceSpeakRequestQueueNotifier extends Notifier<List<VoiceSpeakRequestIncoming>> {
  @override
  List<VoiceSpeakRequestIncoming> build() => const [];

  void enqueue(VoiceSpeakRequestIncoming item) {
    if (item.requestId.isEmpty || item.userId.isEmpty) return;
    final existing = state.any((e) => e.dedupeKey == item.dedupeKey);
    if (existing) return;
    state = [...state, item];
    ref.read(voiceSpeakRequestSignalProvider.notifier).bump();
  }

  void removeForRequest(String roomKey, String requestId) {
    if (requestId.isEmpty) return;
    final next = state
        .where((e) => !(e.roomKey == roomKey && e.requestId == requestId))
        .toList();
    if (next.length != state.length) state = next;
  }

  void removeForUser(String roomKey, String userId) {
    if (userId.isEmpty) return;
    final next =
        state.where((e) => !(e.roomKey == roomKey && e.userId == userId)).toList();
    if (next.length != state.length) state = next;
  }

  void clearRoom(String roomKey) {
    if (roomKey.isEmpty) return;
    final next = state.where((e) => e.roomKey != roomKey).toList();
    if (next.length != state.length) state = next;
  }

  void clear() => state = const [];
}

final voiceSpeakRequestQueueProvider =
    NotifierProvider<VoiceSpeakRequestQueueNotifier, List<VoiceSpeakRequestIncoming>>(
  VoiceSpeakRequestQueueNotifier.new,
);

/// Host popup — aynı istek için çift dialog önlenir.
final voiceSpeakRequestSeenIdsProvider =
    StateProvider<Set<String>>((ref) => {});

class VoiceSpeakRequestUserNotice {
  const VoiceSpeakRequestUserNotice({
    required this.message,
    this.blocked = false,
  });

  final String message;
  final bool blocked;
}

final voiceSpeakRequestUserNoticeProvider =
    StateProvider<VoiceSpeakRequestUserNotice?>((ref) => null);
