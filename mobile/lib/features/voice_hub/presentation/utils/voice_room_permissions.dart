import '../../../auth/domain/entities/user_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';

/// Site admin (`admin` nick, `admin`/`superadmin` rol) her odada tam yetki.
class VoiceRoomPermissions {
  const VoiceRoomPermissions({
    required this.isSiteAdmin,
    required this.isRoomOwner,
    required this.canModerate,
    required this.canManageDj,
    required this.canChangeBackground,
  });

  final bool isSiteAdmin;
  final bool isRoomOwner;
  final bool canModerate;
  final bool canManageDj;
  final bool canChangeBackground;

  bool get hasFullAdmin => isSiteAdmin || isRoomOwner;

  static VoiceRoomPermissions forUser({
    required UserEntity? user,
    required VoiceRoomEntity room,
    ChatRoomPresence? selfPresence,
  }) {
    if (user == null) {
      return const VoiceRoomPermissions(
        isSiteAdmin: false,
        isRoomOwner: false,
        canModerate: false,
        canManageDj: false,
        canChangeBackground: false,
      );
    }

    final uname = user.username.trim().toLowerCase();
    final role = (user.role ?? '').toLowerCase();
    final isSiteAdmin = role == 'admin' ||
        role == 'superadmin' ||
        role == 'moderator' ||
        uname == 'admin' ||
        uname == 'destek' ||
        uname == 'moderator' ||
        selfPresence?.chatRole == 'admin' ||
        selfPresence?.chatRole == 'superadmin';

    final isRoomOwner = isSiteAdmin ||
        (room.ownerId != null && room.ownerId == user.id) ||
        room.slug.trim().toLowerCase() == uname;

    final isDj = room.djUserIds.contains(user.id) ||
        selfPresence?.chatRole == 'dj';

    return VoiceRoomPermissions(
      isSiteAdmin: isSiteAdmin,
      isRoomOwner: isRoomOwner,
      canModerate: isSiteAdmin || isRoomOwner,
      canManageDj: isSiteAdmin || isRoomOwner || isDj,
      canChangeBackground: isSiteAdmin || isRoomOwner,
    );
  }
}
