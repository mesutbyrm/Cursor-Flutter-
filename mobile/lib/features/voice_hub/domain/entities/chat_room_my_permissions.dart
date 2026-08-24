import 'package:equatable/equatable.dart';

/// `GET /api/chat/rooms/{id}/messages` → `myPermissions` (canlifal.com).
class ChatRoomMyPermissions extends Equatable {
  const ChatRoomMyPermissions({
    this.role,
    this.canMuteUsers = false,
    this.canKickUsers = false,
    this.canBanUsers = false,
    this.canMuteRoom = false,
    this.canGiveVoice = false,
    this.canGiveOp = false,
    this.canGiveSop = false,
    this.canGiveFounder = false,
    this.canManageRoom = false,
    this.canSpeakInMutedRoom = false,
    this.isGlobalAdmin = false,
    this.isRoomOwner = false,
  });

  factory ChatRoomMyPermissions.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const ChatRoomMyPermissions();
    bool flag(String camel, [String? snake]) {
      final raw = json[camel] ?? (snake != null ? json[snake] : null);
      if (raw == true || raw == 1) return true;
      if (raw == false || raw == 0 || raw == null) return false;
      final s = raw.toString().trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }

    return ChatRoomMyPermissions(
      role: (json['role'] ?? json['chatRole'])?.toString(),
      canMuteUsers: flag('canMuteUsers', 'can_mute_users'),
      canKickUsers: flag('canKickUsers', 'can_kick_users'),
      canBanUsers: flag('canBanUsers', 'can_ban_users'),
      canMuteRoom: flag('canMuteRoom', 'can_mute_room'),
      canGiveVoice: flag('canGiveVoice', 'can_give_voice'),
      canGiveOp: flag('canGiveOp', 'can_give_op'),
      canGiveSop: flag('canGiveSop', 'can_give_sop'),
      canGiveFounder: flag('canGiveFounder', 'can_give_founder'),
      canManageRoom: flag('canManageRoom', 'can_manage_room'),
      canSpeakInMutedRoom:
          flag('canSpeakInMutedRoom', 'can_speak_in_muted_room'),
      isGlobalAdmin: flag('isGlobalAdmin', 'is_global_admin'),
      isRoomOwner: flag('isRoomOwner', 'is_room_owner'),
    );
  }

  final String? role;
  final bool canMuteUsers;
  final bool canKickUsers;
  final bool canBanUsers;
  final bool canMuteRoom;
  final bool canGiveVoice;
  final bool canGiveOp;
  final bool canGiveSop;
  final bool canGiveFounder;
  final bool canManageRoom;
  final bool canSpeakInMutedRoom;
  final bool isGlobalAdmin;
  final bool isRoomOwner;

  bool get canModerate =>
      canMuteUsers ||
      canKickUsers ||
      canBanUsers ||
      canManageRoom ||
      canGiveVoice ||
      canGiveOp ||
      canGiveSop ||
      canGiveFounder ||
      isGlobalAdmin ||
      isRoomOwner;

  /// Sunucu herhangi bir yetki bayrağı gönderdiyse client bunları kullanmalı.
  bool get hasAnyServerFlag =>
      canMuteUsers ||
      canKickUsers ||
      canBanUsers ||
      canMuteRoom ||
      canGiveVoice ||
      canGiveOp ||
      canGiveSop ||
      canGiveFounder ||
      canManageRoom ||
      canSpeakInMutedRoom ||
      isGlobalAdmin ||
      isRoomOwner;

  @override
  List<Object?> get props => [
        role,
        canMuteUsers,
        canKickUsers,
        canBanUsers,
        canMuteRoom,
        canGiveVoice,
        canGiveOp,
        canGiveSop,
        canGiveFounder,
        canManageRoom,
        canSpeakInMutedRoom,
        isGlobalAdmin,
        isRoomOwner,
      ];
}
