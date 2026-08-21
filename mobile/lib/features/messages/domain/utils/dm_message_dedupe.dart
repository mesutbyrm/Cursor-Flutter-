import '../../domain/entities/message_entities.dart';

/// Mesaj listesinde aynı `messageId` iki kez gösterilmesin.
List<MessageEntity> dedupeMessagesById(List<MessageEntity> messages) {
  final seen = <String>{};
  final out = <MessageEntity>[];
  for (final m in messages) {
    final id = m.id.trim();
    if (id.isEmpty) {
      out.add(m);
      continue;
    }
    if (!seen.add(id)) continue;
    out.add(m);
  }
  return out;
}
