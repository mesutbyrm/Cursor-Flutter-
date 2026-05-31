import '../../../../core/auth/voice_staff_rank.dart';
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

  /// Boş koltuğa oturma (moderatör, DJ, oda sahibi).
  bool get canTakeSeat => canModerate || isRoomOwner || canManageDj;

  /// Başkasını koltuğa oturtma (oda sahibi / moderasyon).
  bool get canAssignSeats => isRoomOwner || canModerate;

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

    final rank = VoiceStaffRankParser.resolve(
      username: user.username,
      role: user.role,
      chatRole: selfPresence?.chatRole,
    );
    final staffPower = VoiceStaffRankParser.powerLevel(rank);
    final isSiteAdmin = staffPower >= VoiceStaffRankParser.powerLevel(VoiceStaffRank.admin) ||
        selfPresence?.chatRole == 'admin' ||
        selfPresence?.chatRole == 'founder' ||
        selfPresence?.chatRole == 'sop';

    final uname = user.username.trim().toLowerCase();
    final isRoomOwner = isSiteAdmin ||
        staffPower >= VoiceStaffRankParser.powerLevel(VoiceStaffRank.founder) ||
        (room.ownerId != null && room.ownerId == user.id) ||
        room.slug.trim().toLowerCase() == uname;

    final isDj = room.djUserIds.contains(user.id) ||
        selfPresence?.chatRole == 'dj' ||
        VoiceStaffRankParser.canModerate(rank);

    final canModerate = isSiteAdmin ||
        isRoomOwner ||
        VoiceStaffRankParser.canModerate(rank);

    return VoiceRoomPermissions(
      isSiteAdmin: isSiteAdmin,
      isRoomOwner: isRoomOwner,
      canModerate: canModerate,
      canManageDj: isSiteAdmin || isRoomOwner || isDj,
      canChangeBackground: isSiteAdmin || isRoomOwner || canModerate,
    );
  }
}
