import '../../../../core/auth/staff_roles.dart';
import '../../../../core/auth/voice_staff_rank.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_my_permissions.dart';
import '../../domain/entities/chat_room_presence.dart';

/// Site admin + oda içi IRC rolleri; sunucu `myPermissions` önceliklidir.
class VoiceRoomPermissions {
  const VoiceRoomPermissions({
    required this.isSiteAdmin,
    required this.isRoomOwner,
    required this.canModerate,
    required this.canManageDj,
    required this.canChangeBackground,
    this.canMuteUsers = false,
    this.canKickUsers = false,
    this.canBanUsers = false,
    this.canMuteRoom = false,
    this.canGiveVoice = false,
    this.canGiveOp = false,
    this.canGiveSop = false,
    this.canGiveFounder = false,
    this.canManageRoom = false,
  });

  final bool isSiteAdmin;
  final bool isRoomOwner;
  final bool canModerate;
  final bool canManageDj;
  final bool canChangeBackground;
  final bool canMuteUsers;
  final bool canKickUsers;
  final bool canBanUsers;
  final bool canMuteRoom;
  final bool canGiveVoice;
  final bool canGiveOp;
  final bool canGiveSop;
  final bool canGiveFounder;
  final bool canManageRoom;

  bool get hasFullAdmin => isSiteAdmin || isRoomOwner;

  bool get canTakeSeat => canModerate || isRoomOwner || canManageDj || canGiveVoice;

  bool get canAssignSeats => isRoomOwner || canManageRoom || canModerate;

  bool get canManageUsers =>
      canModerate ||
      canMuteUsers ||
      canKickUsers ||
      canBanUsers ||
      canGiveVoice ||
      canGiveOp ||
      canGiveSop ||
      isRoomOwner ||
      isSiteAdmin;

  bool get canManageChat =>
      canModerate || canMuteRoom || isRoomOwner || isSiteAdmin;

  bool get canManageRoomSettings =>
      canManageRoom ||
      canChangeBackground ||
      canManageDj ||
      isRoomOwner ||
      isSiteAdmin;

  static VoiceRoomPermissions forUser({
    required UserEntity? user,
    required VoiceRoomEntity room,
    ChatRoomPresence? selfPresence,
    ChatRoomMyPermissions? server,
    bool staffSiteAdmin = false,
    String? walletRole,
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

    final effectiveRole = walletRole?.trim().isNotEmpty == true
        ? walletRole
        : user.role;

    if (staffSiteAdmin ||
        StaffRoles.isSiteAdminUser(
          role: effectiveRole,
          username: user.username,
        )) {
      return const VoiceRoomPermissions(
        isSiteAdmin: true,
        isRoomOwner: true,
        canModerate: true,
        canManageDj: true,
        canChangeBackground: true,
        canMuteUsers: true,
        canKickUsers: true,
        canBanUsers: true,
        canMuteRoom: true,
        canGiveVoice: true,
        canGiveOp: true,
        canGiveSop: true,
        canGiveFounder: true,
        canManageRoom: true,
      );
    }

    // Sunucu `canGiveVoice` vb. gönderdiyse `canModerate` false olsa bile uygula.
    if (server != null && (server.canModerate || server.hasAnyServerFlag)) {
      return VoiceRoomPermissions(
        isSiteAdmin: server.isGlobalAdmin,
        isRoomOwner: server.isRoomOwner,
        canModerate: server.canModerate,
        canManageDj: server.canManageRoom ||
            server.isGlobalAdmin ||
            server.isRoomOwner ||
            server.canGiveVoice,
        canChangeBackground: server.canManageRoom ||
            server.isGlobalAdmin ||
            server.isRoomOwner,
        canMuteUsers: server.canMuteUsers,
        canKickUsers: server.canKickUsers,
        canBanUsers: server.canBanUsers,
        canMuteRoom: server.canMuteRoom,
        canGiveVoice: server.canGiveVoice ||
            server.isRoomOwner ||
            server.canManageRoom,
        canGiveOp: server.canGiveOp ||
            server.isRoomOwner ||
            server.isGlobalAdmin,
        canGiveSop: server.canGiveSop ||
            server.isRoomOwner ||
            server.isGlobalAdmin,
        canGiveFounder: server.canGiveFounder || server.isGlobalAdmin,
        canManageRoom: server.canManageRoom,
      );
    }

    final rank = VoiceStaffRankParser.resolve(
      username: user.username,
      role: effectiveRole,
      chatRole: selfPresence?.chatRole ?? server?.role,
    );
    final staffPower = VoiceStaffRankParser.powerLevel(rank);
    final isSiteAdmin = staffSiteAdmin ||
        StaffRoles.isSiteAdminUser(
          role: effectiveRole,
          username: user.username,
        ) ||
        server?.isGlobalAdmin == true ||
        staffPower >= VoiceStaffRankParser.powerLevel(VoiceStaffRank.admin) ||
        selfPresence?.chatRole == 'admin' ||
        selfPresence?.chatRole == 'superadmin';

    final uname = user.username.trim().toLowerCase();
    final isRoomOwner = server?.isRoomOwner == true ||
        isSiteAdmin ||
        staffPower >= VoiceStaffRankParser.powerLevel(VoiceStaffRank.founder) ||
        (room.ownerId != null && room.ownerId == user.id) ||
        room.slug.trim().toLowerCase() == uname;

    final isDj = room.djUserIds.contains(user.id) ||
        selfPresence?.chatRole == 'dj';

    final canMuteUsers = staffPower >=
        VoiceStaffRankParser.powerLevel(VoiceStaffRank.op);
    final canKickBan = staffPower >=
        VoiceStaffRankParser.powerLevel(VoiceStaffRank.sop);
    final canManageRoom = isSiteAdmin ||
        isRoomOwner ||
        staffPower >= VoiceStaffRankParser.powerLevel(VoiceStaffRank.founder);

    final canModerate = canMuteUsers || canKickBan || canManageRoom;

    return VoiceRoomPermissions(
      isSiteAdmin: isSiteAdmin,
      isRoomOwner: isRoomOwner,
      canModerate: canModerate,
      canManageDj: isSiteAdmin || isRoomOwner || isDj || canManageRoom,
      canChangeBackground: canManageRoom || canModerate,
      canMuteUsers: canMuteUsers,
      canKickUsers: canKickBan,
      canBanUsers: canKickBan,
      canMuteRoom: canKickBan,
      canGiveVoice: canMuteUsers || isRoomOwner || canManageRoom,
      canGiveOp: canMuteUsers || isRoomOwner || canManageRoom,
      canGiveSop: canKickBan || isRoomOwner || canManageRoom,
      canGiveFounder: isSiteAdmin || isRoomOwner,
      canManageRoom: canManageRoom,
    );
  }
}
