import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Oda sahibine gelen şifre erişim isteği (SSE veya presence yansıması).
class VoiceRoomPasswordRequestEntry {
  const VoiceRoomPasswordRequestEntry({
    required this.roomKey,
    required this.requesterUserId,
    required this.requesterName,
    this.message,
  });

  final String roomKey;
  final String requesterUserId;
  final String requesterName;
  final String? message;

  String get dedupKey => '${roomKey.trim()}:${requesterUserId.trim()}';
}

class VoiceRoomPasswordRequestQueue extends Notifier<List<VoiceRoomPasswordRequestEntry>> {
  @override
  List<VoiceRoomPasswordRequestEntry> build() => const [];

  void enqueue(VoiceRoomPasswordRequestEntry entry) {
    if (entry.roomKey.isEmpty || entry.requesterUserId.isEmpty) return;
    final key = entry.dedupKey;
    if (state.any((e) => e.dedupKey == key)) return;
    state = [...state, entry];
  }

  void remove(String dedupKey) {
    state = state.where((e) => e.dedupKey != dedupKey).toList(growable: false);
  }
}

final voiceRoomPasswordRequestQueueProvider =
    NotifierProvider<VoiceRoomPasswordRequestQueue, List<VoiceRoomPasswordRequestEntry>>(
  VoiceRoomPasswordRequestQueue.new,
);

class VoicePasswordRequestSignalNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final voicePasswordRequestSignalProvider =
    NotifierProvider<VoicePasswordRequestSignalNotifier, int>(
  VoicePasswordRequestSignalNotifier.new,
);
