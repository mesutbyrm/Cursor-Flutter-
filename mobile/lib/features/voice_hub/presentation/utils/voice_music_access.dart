import '../../../auth/domain/entities/user_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/music_queue_item.dart';
import 'voice_room_permissions.dart';

/// «Müzik Aç» kartı: DJ yetkisi veya yeterli jeton.
abstract final class VoiceMusicAccess {
  /// Sağ ‹ DJ & müzik paneli — DJ, oda sahibi veya site admin.
  static bool canShowDjMusicPanel({
    required VoiceRoomPermissions perms,
    required bool isDj,
  }) {
    return perms.isRoomOwner ||
        perms.isSiteAdmin ||
        perms.canManageDj ||
        isDj;
  }

  static bool canShowMusicCard({
    required ChatRoomDjState dj,
    required VoiceRoomPermissions perms,
    required int jetonBalance,
  }) {
    if (!dj.musicEnabled) return false;
    if (perms.canManageDj || dj.canPlayMusic) return true;
    return jetonBalance >= dj.musicRequestCost;
  }

  static bool canRequestSongs({
    required ChatRoomDjState dj,
    required VoiceRoomPermissions perms,
    required int jetonBalance,
  }) {
    if (!dj.musicEnabled) return false;
    if (dj.canRequestMusic) return true;
    return jetonBalance >= audioRequestCost(dj);
  }

  /// Sesli istek — 10 jeton (sunucu yoksa varsayılan).
  static int audioRequestCost(ChatRoomDjState dj) =>
      dj.musicRequestCost > 0 ? dj.musicRequestCost : 10;

  /// Videolu istek — 20 jeton (sunucu yoksa varsayılan).
  static int videoRequestCost(ChatRoomDjState dj) =>
      dj.videoRequestCost > 0 ? dj.videoRequestCost : 20;

  static bool canAffordRequest({
    required ChatRoomDjState dj,
    required int jetonBalance,
    required bool withVideo,
  }) {
    final cost = withVideo ? videoRequestCost(dj) : audioRequestCost(dj);
    return jetonBalance >= cost;
  }

  /// Müziği durdurma — yalnızca oda sahibi, site admin veya isteyen.
  static bool canStopMusic({
    required UserEntity? user,
    required VoiceRoomPermissions perms,
    required MusicQueueItem? nowPlaying,
  }) {
    if (user == null) return false;
    if (perms.isRoomOwner || perms.isSiteAdmin) return true;
    return nowPlaying?.requestedBy?.id == user.id;
  }

  static int jetonFromBalances(WalletBalances? balances) =>
      balances?.jeton ?? 0;

  static VoiceRoomPermissions permissionsFor({
    required UserEntity? user,
    required VoiceRoomEntity room,
    required List<ChatRoomPresence> presence,
  }) {
    ChatRoomPresence? self;
    if (user != null) {
      for (final p in presence) {
        if (p.id == user.id) {
          self = p;
          break;
        }
      }
    }
    return VoiceRoomPermissions.forUser(
      user: user,
      room: room,
      selfPresence: self,
    );
  }
}
