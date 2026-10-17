import '../../domain/entities/chat_room_message.dart';
import '../../domain/voice_music_sync.dart';
import '../../domain/voice_official_join.dart';

/// Sohbet listesinde gösterilmeyecek mesajlar — komut, istek logları.
/// Giriş/çıkış satırları sohbette gösterilir.
abstract final class VoiceChatMessageFilters {
  /// GirLive Bot'un giriş selamı («👋 Hoş geldin @isim!»).
  static bool isBotWelcome(ChatRoomMessage message) {
    final name = (message.user?.name ?? '').toLowerCase();
    return name.contains('girlive') && looksLikeWelcome(message.content);
  }

  static bool looksLikeWelcome(String content) {
    final lower = content.toLowerCase();
    return lower.contains('hoş geldin') ||
        lower.contains('hoşgeldin') ||
        lower.contains('hos geldin');
  }

  /// Selamın sayaç başlangıcı: mesaj zamanı (geçmişten yüklenen eski selam
  /// hemen gizlenir); sunucu saati ilerideyse şimdi.
  static DateTime welcomeClockStart(DateTime createdAt, DateTime now) =>
      createdAt.isBefore(now) ? createdAt : now;

  /// Selam bu süre sonra sohbetten kalkar.
  static const botWelcomeVisible = Duration(seconds: 10);

  /// Yayıncı asistanına ait metin genel sohbette görünmemeli.
  static bool isPublisherPrivateLeak(ChatRoomMessage message) {
    final content = message.content;
    if (content.contains('[GIRLIVE_PUBLISHER]')) return true;
    final lower = content.toLowerCase();
    if (lower.contains('yayıncı asistanım') &&
        (lower.contains('jeton değerinde hediye') ||
            lower.contains('tekil ziyaretçi'))) {
      return true;
    }
    return false;
  }

  static bool shouldShow(ChatRoomMessage message) {
    if (message.kind == ChatMessageKind.systemJoin ||
        message.kind == ChatMessageKind.systemLeave) {
      return true;
    }

    final content = message.content.trim();
    if (content.isEmpty) return true;

    if (isPublisherPrivateLeak(message)) return false;

    if (ChatRoomMessage.isSystemProtocol(content)) return false;

    if (message.kind == ChatMessageKind.gift) return false;

    // DJ isteği kaydı (sunucu verisi) sohbette görünmez; duyurusu ayrıca gelir.
    if (content.trimLeft().startsWith('[DJ_REQ]')) return false;
    if (_isSongRequestAnnouncement(content)) return true;

    if (_isTechnicalMusicLine(content)) return false;
    if (VoiceMusicSync.isIstekCommand(content)) return false;
    if (_isIstekEcho(content)) return false;
    if (VoiceOfficialJoin.looksLikeRoomCommand(content)) return false;
    if (VoiceOfficialJoin.isClearChatCommand(content)) return false;

    final lower = content.toLowerCase();
    if (lower.contains('odaya giriş') ||
        lower.contains('odadan ayrıldı') ||
        lower.contains('katıldı!')) {
      return false;
    }

    return true;
  }

  static bool _isTechnicalMusicLine(String content) {
    final c = content.trim();
    if (c.startsWith('🎵') ||
        c.startsWith('🎁') ||
        c.startsWith('📀') ||
        c.startsWith('🔢') ||
        c.startsWith('⏭️') ||
        c.startsWith('🗑️') ||
        c.startsWith('🧹')) {
      return true;
    }
    return c.contains('[SONG_REQUEST') ||
        c.contains('[PLAYED]') ||
        c.contains('QUEUE_UPDATE');
  }

  static bool _isSongRequestAnnouncement(String content) {
    final lower = content.toLowerCase();
    if (content.startsWith('🎵') && lower.contains('şarkı')) return true;
    return lower.contains('şarkı isteği gönderdi') ||
        lower.contains('şarkı istedi:') ||
        lower.contains('sıraya eklendi');
  }

  static bool _isIstekEcho(String content) {
    final lower = content.toLowerCase();
    return lower.startsWith('!istek') || lower.contains('şarkı isteği:');
  }
}
