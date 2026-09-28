import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_room_presence.dart';

class VoiceSessionVisitor {
  const VoiceSessionVisitor({
    required this.id,
    required this.name,
    this.image,
  });

  final String id;
  final String name;
  final String? image;
}

/// Bir sesli oda oturumunda (girişten çıkışa) odaya giren kullanıcılar.
class VoiceSessionVisitors {
  const VoiceSessionVisitors({
    required this.roomKey,
    required this.startedAt,
    this.visitors = const {},
  });

  final String roomKey;
  final DateTime startedAt;
  final Map<String, VoiceSessionVisitor> visitors;

  VoiceSessionVisitors copyWithVisitors(Map<String, VoiceSessionVisitor> v) =>
      VoiceSessionVisitors(roomKey: roomKey, startedAt: startedAt, visitors: v);
}

class VoiceSessionVisitorsNotifier extends StateNotifier<VoiceSessionVisitors?> {
  VoiceSessionVisitorsNotifier() : super(null);

  /// Oda sayfası her açıldığında yeni oturum başlar.
  void start(String roomKey) {
    final key = roomKey.trim();
    if (key.isEmpty) return;
    state = VoiceSessionVisitors(roomKey: key, startedAt: DateTime.now());
  }

  void record(
    String roomKey,
    List<ChatRoomPresence> presence, {
    String? myUserId,
  }) {
    final current = state;
    if (current == null || current.roomKey != roomKey.trim()) return;
    Map<String, VoiceSessionVisitor>? next;
    for (final p in presence) {
      final id = p.id.trim();
      if (id.isEmpty || id == myUserId) continue;
      if (current.visitors.containsKey(id) || (next?.containsKey(id) ?? false)) {
        continue;
      }
      next ??= Map.of(current.visitors);
      next[id] = VoiceSessionVisitor(id: id, name: p.displayName, image: p.image);
    }
    if (next != null) state = current.copyWithVisitors(next);
  }

  /// Çıkışta özet alındıktan sonra bir sonraki oturum temiz başlar.
  VoiceSessionVisitors? takeAndReset(String roomKey) {
    final current = state;
    if (current == null || current.roomKey != roomKey.trim()) return null;
    state = null;
    return current;
  }
}

/// Oda sayfasının `initState`'inden çağrılır; abonelik sayfa ile kapanır.
void trackVoiceSessionVisitors(
  WidgetRef ref,
  String roomKey, {
  required ProviderListenable<List<ChatRoomPresence>> presence,
  String? myUserId,
}) {
  final key = roomKey.trim();
  if (key.isEmpty) return;
  final notifier = ref.read(voiceSessionVisitorsProvider.notifier)..start(key);
  ref.listenManual<List<ChatRoomPresence>>(
    presence,
    (_, next) => notifier.record(key, next, myUserId: myUserId),
    fireImmediately: true,
  );
}

final voiceSessionVisitorsProvider =
    StateNotifierProvider<VoiceSessionVisitorsNotifier, VoiceSessionVisitors?>(
  (ref) => VoiceSessionVisitorsNotifier(),
);
