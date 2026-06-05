/// Web ↔ mobil müzik kuyruğu senkronu — sohbet komutları ve sistem mesajları.
abstract final class VoiceMusicSync {
  /// `!istek şarkı` / `/istek şarkı` → şarkı adı (boş = yalnızca komut).
  static String? parseIstekSongTitle(String text) {
    final t = text.trim();
    final m = RegExp(
      r'^[!/]istek(?:\s+(.+))?$',
      caseSensitive: false,
    ).firstMatch(t);
    if (m == null) return null;
    return m.group(1)?.trim();
  }

  static bool isIstekCommand(String text) {
    final t = text.trim().toLowerCase();
    return t.startsWith('!istek') || t.startsWith('/istek');
  }

  /// Sunucunun kuyruk güncellemesi sonrası gönderdiği sohbet satırları.
  static bool isQueueUpdateMessage(String content) {
    final c = content.trim().toLowerCase();
    if (c.isEmpty) return false;
    return c.contains('kuyruğa eklendi') ||
        c.contains('şarkısını istedi') ||
        c.contains('sıra: #') ||
        c.contains('şarkı isteği alındı') ||
        c.contains('şarkıyı atladı') ||
        c.contains('kuyruktan kaldırıldı') ||
        c.contains('müzik kuyruğu temizlendi') ||
        c.contains('şu an çalıyor') ||
        c.contains('şimdi çalıyor') ||
        c.startsWith('!istek') ||
        c.startsWith('/istek');
  }
}
