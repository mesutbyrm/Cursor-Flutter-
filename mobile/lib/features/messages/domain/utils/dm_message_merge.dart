import '../entities/message_entities.dart';

/// Sunucu listesi ile ekrandaki mesajları KİMLİĞE göre birleştirir (ezmez).
///
/// Neden: sunucudan gelen liste bayat olabilir (GET gönderimden önce başladıysa
/// ya da arka uç yalnızca en eski 100 mesajı döndürüyorsa). Eskiden yenileme
/// ekrandaki listeyi sunucu listesiyle değiştirdiği için yeni gönderilen
/// (optimistic) mesaj birkaç saniye sonra kayboluyordu.
abstract final class DmMessageMerge {
  static const optimisticPrefix = 'local-';
  static const ssePrefix = 'sse-';

  static bool isPending(MessageEntity m) =>
      m.id.startsWith(optimisticPrefix) || m.id.startsWith(ssePrefix);

  /// [previous]: şu an ekrandaki liste. [remote]: sunucudan yeni gelen liste.
  ///
  ///  * Aynı kimlik → sunucu sürümü kazanır.
  ///  * `local-*` / `sse-*` mesajlar sunucuda eşi (aynı yön + metin + zaman
  ///    penceresi) görünene kadar korunur.
  ///  * Sunucu listesinde olmayan ama sunucunun döndürdüğü en yeni mesajdan
  ///    DAHA YENİ olan mesajlar korunur (sunucu sayfa sınırı/gecikmesi).
  static List<MessageEntity> mergeById({
    required List<MessageEntity> previous,
    required List<MessageEntity> remote,
    Duration window = const Duration(minutes: 2),
  }) {
    final out = <MessageEntity>[];
    final seen = <String>{};
    DateTime? newestRemote;

    for (final m in remote) {
      final id = m.id.trim();
      if (id.isNotEmpty && !seen.add(id)) continue;
      out.add(m);
      final at = m.createdAt;
      if (at != null && (newestRemote == null || at.isAfter(newestRemote))) {
        newestRemote = at;
      }
    }

    bool confirmedByRemote(MessageEntity m) {
      final t = m.text.trim();
      for (final r in remote) {
        if (r.isMine != m.isMine || r.text.trim() != t) continue;
        final a = r.createdAt, b = m.createdAt;
        if (a == null || b == null) return true;
        if (a.difference(b).abs() < window) return true;
      }
      return false;
    }

    for (final m in previous) {
      final id = m.id.trim();
      if (id.isNotEmpty && seen.contains(id)) continue;
      if (isPending(m)) {
        if (!confirmedByRemote(m)) {
          out.add(m);
          if (id.isNotEmpty) seen.add(id);
        }
        continue;
      }
      // Sunucu kimlikli ama sunucu listesinde olmayan: yalnızca daha yeniyse tut.
      final at = m.createdAt;
      final newer = at != null && (newestRemote == null || at.isAfter(newestRemote));
      if (newer) {
        out.add(m);
        if (id.isNotEmpty) seen.add(id);
      }
    }

    out.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return at.compareTo(bt);
    });
    return out;
  }

  /// Tek mesaj ekle/güncelle (SSE): aynı kimlik → değiştirir; eşleşen
  /// optimistic mesaj → yerine geçer; diğer mesajlara dokunmaz.
  static List<MessageEntity> upsert(
    List<MessageEntity> current,
    MessageEntity incoming, {
    Duration window = const Duration(minutes: 2),
  }) {
    final out = <MessageEntity>[];
    var replaced = false;
    for (final m in current) {
      if (m.id.isNotEmpty && m.id == incoming.id) {
        out.add(incoming);
        replaced = true;
        continue;
      }
      if (isPending(m) &&
          m.isMine == incoming.isMine &&
          m.text.trim() == incoming.text.trim() &&
          _within(m.createdAt, incoming.createdAt, window)) {
        // optimistic → sunucu kaydı
        if (!replaced) {
          out.add(incoming);
          replaced = true;
        }
        continue;
      }
      out.add(m);
    }
    if (!replaced) out.add(incoming);
    out.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return at.compareTo(bt);
    });
    return out;
  }

  static bool _within(DateTime? a, DateTime? b, Duration window) {
    if (a == null || b == null) return true;
    return a.difference(b).abs() < window;
  }
}
