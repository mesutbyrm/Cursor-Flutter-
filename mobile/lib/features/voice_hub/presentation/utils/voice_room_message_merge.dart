import '../../domain/entities/chat_room_message.dart';

/// Sohbet mesajlarını birleştirir; optimistic `local-*` id'leri sunucu yanıtıyla değiştirir.
abstract final class VoiceRoomMessageMerge {
  static List<ChatRoomMessage> merge(
    List<ChatRoomMessage> current,
    List<ChatRoomMessage> fetched,
  ) {
    final byId = <String, ChatRoomMessage>{};
    for (final m in current) {
      byId[m.id] = m;
    }
    for (final m in fetched) {
      final dupKeys = byId.entries
          .where(
            (e) =>
                e.key.startsWith('local-') &&
                e.value.content == m.content &&
                e.value.user?.id == m.user?.id,
          )
          .map((e) => e.key)
          .toList();
      for (final key in dupKeys) {
        byId.remove(key);
      }
      byId[m.id] = m;
    }
    final merged = byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }
}
