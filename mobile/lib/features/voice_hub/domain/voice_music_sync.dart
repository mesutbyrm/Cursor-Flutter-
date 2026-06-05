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

  /// Üretim sohbet formatı: `[SONG_REQUEST_FREE] videoId|başlık|||`
  static SongRequestFreePayload? parseSongRequestFree(String content) {
    final raw = content.trim();
    if (raw.isEmpty) return null;
    final m = RegExp(
      r'\[SONG_REQUEST_FREE\]\s*([^\s|]+)\|([^|]*)(?:\|*)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (m == null) return null;
    final videoId = m.group(1)?.trim() ?? '';
    if (videoId.isEmpty) return null;
    final title = m.group(2)?.trim() ?? '';
    return SongRequestFreePayload(
      videoId: videoId,
      title: title.isNotEmpty ? title : 'Şarkı',
    );
  }

  /// Sunucunun kuyruk güncellemesi sonrası gönderdiği sohbet satırları.
  static bool isQueueUpdateMessage(String content) {
    final c = content.trim().toLowerCase();
    if (c.isEmpty) return false;
    if (c.contains('[song_request_free]')) return true;
    return c.contains('kuyruğa eklendi') ||
        c.contains('şarkısını istedi') ||
        c.contains('sıra: #') ||
        c.contains('şarkı isteği alındı') ||
        c.contains('şarkı isteği gönderdi') ||
        c.contains('şarkıyı atladı') ||
        c.contains('kuyruktan kaldırıldı') ||
        c.contains('müzik kuyruğu temizlendi') ||
        c.contains('şu an çalıyor') ||
        c.contains('şimdi çalıyor') ||
        c.contains('öncelikli istek') ||
        c.contains('müzik durduruldu') ||
        c.startsWith('!istek') ||
        c.startsWith('/istek');
  }
}

/// `[SONG_REQUEST_FREE] videoId|title|||` satırından çıkarılan veri.
class SongRequestFreePayload {
  const SongRequestFreePayload({
    required this.videoId,
    required this.title,
  });

  final String videoId;
  final String title;

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$videoId';
}
