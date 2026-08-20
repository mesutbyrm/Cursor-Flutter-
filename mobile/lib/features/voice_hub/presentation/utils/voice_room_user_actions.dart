import '../../domain/entities/chat_room_presence.dart';
import 'voice_room_permissions.dart';

/// Yetkili kullanıcı popup'ı — chat, koltuk ve katılımcı listesinde aynı kural.
abstract final class VoiceRoomUserActions {
  /// Mute/kick/voice vb. yetkisi olanlar moderasyon sayfasını açar.
  static bool canOpenModerationSheet(VoiceRoomPermissions perms) =>
      perms.canManageUsers;

  /// Kendi profiline tıklanınca moderasyon yerine profil (tam mod hariç).
  static bool shouldOpenSelfProfile({
    required VoiceRoomPermissions perms,
    required String? selfId,
    required ChatRoomPresence target,
  }) {
    if (selfId == null || selfId != target.id) return false;
    return !perms.canModerate && !perms.isRoomOwner && !perms.isSiteAdmin;
  }
}
