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
    bool flag(String key) => json[key] == true;
    return ChatRoomMyPermissions(
      role: json['role']?.toString(),
      canMuteUsers: flag('canMuteUsers'),
      canKickUsers: flag('canKickUsers'),
      canBanUsers: flag('canBanUsers'),
      canMuteRoom: flag('canMuteRoom'),
      canGiveVoice: flag('canGiveVoice'),
      canGiveOp: flag('canGiveOp'),
      canGiveSop: flag('canGiveSop'),
      canGiveFounder: flag('canGiveFounder'),
      canManageRoom: flag('canManageRoom'),
      canSpeakInMutedRoom: flag('canSpeakInMutedRoom'),
      isGlobalAdmin: flag('isGlobalAdmin'),
      isRoomOwner: flag('isRoomOwner'),
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
