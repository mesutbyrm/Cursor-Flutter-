import '../../../auth/domain/entities/user_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_presence.dart';
import 'voice_room_permissions.dart';

/// «Müzik Aç» kartı: DJ yetkisi veya yeterli jeton.
abstract final class VoiceMusicAccess {
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
    return canShowMusicCard(
      dj: dj,
      perms: perms,
      jetonBalance: jetonBalance,
    );
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
