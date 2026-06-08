import '../../domain/entities/chat_room_message.dart';
import '../../domain/voice_music_sync.dart';
import '../../domain/voice_official_join.dart';

/// Sohbet listesinde gösterilmeyecek mesajlar — giriş/çıkış, komut, istek logları.
abstract final class VoiceChatMessageFilters {
  static bool shouldShow(ChatRoomMessage message) {
    if (message.kind == ChatMessageKind.systemJoin ||
        message.kind == ChatMessageKind.systemLeave) {
      return false;
    }

    final content = message.content.trim();
    if (content.isEmpty) return true;

    if (message.kind == ChatMessageKind.gift) return true;

    if (_isTechnicalMusicLine(content)) return false;
    if (VoiceMusicSync.isIstekCommand(content)) return false;
    if (_isIstekEcho(content)) return false;
    if (VoiceOfficialJoin.looksLikeRoomCommand(content)) return false;
    if (VoiceOfficialJoin.isClearChatCommand(content)) return false;

    final lower = content.toLowerCase();
    if (lower.contains('odaya giriş') ||
        lower.contains('odadan ayrıldı') ||
        lower.contains('katıldı!') ||
        lower.contains('giriş yaptı')) {
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

  static bool _isIstekEcho(String content) {
    final lower = content.toLowerCase();
    return lower.startsWith('!istek') ||
        lower.contains('şarkı isteği gönderdi') ||
        lower.contains('şarkı isteği:');
  }
}
