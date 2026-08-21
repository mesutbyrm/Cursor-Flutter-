import '../entities/message_entities.dart';

/// Aynı messageId iki kez listelenmesin; optimistic local-* korunur.
abstract final class DmMessageDedupe {
  static List<MessageEntity> merge({
    required List<MessageEntity> remote,
    List<MessageEntity> localOptimistic = const [],
  }) {
    final seen = <String>{};
    final out = <MessageEntity>[];

    for (final m in remote) {
      final id = m.id.trim();
      if (id.isEmpty) {
        out.add(m);
        continue;
      }
      if (!seen.add(id)) continue;
      out.add(m);
    }

    for (final m in localOptimistic) {
      if (!m.id.startsWith('local-')) continue;
      final duplicate = out.any(
        (r) =>
            r.isMine == m.isMine &&
            r.text.trim() == m.text.trim() &&
            r.createdAt != null &&
            m.createdAt != null &&
            r.createdAt!.difference(m.createdAt!).inSeconds.abs() < 30,
      );
      if (duplicate) continue;
      out.add(m);
    }

    out.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return at.compareTo(bt);
    });
    return out;
  }
}
