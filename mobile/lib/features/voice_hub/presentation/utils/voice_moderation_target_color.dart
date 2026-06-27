import 'package:flutter/material.dart';

import '../../../../core/auth/voice_staff_rank.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../utils/voice_room_permissions.dart';

/// Web ile aynı kick/ban kullanıcı listesi renk kodları.
enum VoiceModerationTargetColor {
  green,
  yellow,
  red,
  black,
}

abstract final class VoiceModerationTargetColorResolver {
  static VoiceModerationTargetColor resolve({
    required VoiceRoomPermissions actor,
    required ChatRoomPresence target,
    required bool kickAction,
  }) {
    final targetRank = VoiceStaffRankParser.resolve(
      username: target.nickname ?? target.name,
      chatRole: target.chatRole,
      role: target.roleSymbol,
    );
    if (targetRank == VoiceStaffRank.admin ||
        target.chatRole == 'admin' ||
        target.chatRole == 'superadmin') {
      return VoiceModerationTargetColor.black;
    }
    final actorRank = _actorRank(actor);
    final actorPower = VoiceStaffRankParser.powerLevel(actorRank);
    final targetPower = VoiceStaffRankParser.powerLevel(targetRank);

    if (kickAction && !actor.canKickUsers && !actor.isRoomOwner) {
      return VoiceModerationTargetColor.red;
    }
    if (!kickAction && !actor.canBanUsers && !actor.isRoomOwner) {
      return VoiceModerationTargetColor.red;
    }
    if (actorPower < targetPower) {
      return VoiceModerationTargetColor.red;
    }
    if (actorPower == targetPower) {
      return VoiceModerationTargetColor.yellow;
    }
    return VoiceModerationTargetColor.green;
  }

  static VoiceStaffRank _actorRank(VoiceRoomPermissions actor) {
    if (actor.isSiteAdmin) return VoiceStaffRank.admin;
    if (actor.isRoomOwner) return VoiceStaffRank.founder;
    if (actor.canBanUsers) return VoiceStaffRank.sop;
    if (actor.canKickUsers) return VoiceStaffRank.op;
    if (actor.canMuteUsers) return VoiceStaffRank.op;
    return VoiceStaffRank.none;
  }

  static Color valueOf(VoiceModerationTargetColor c) => switch (c) {
        VoiceModerationTargetColor.green => const Color(0xFF22C55E),
        VoiceModerationTargetColor.yellow => const Color(0xFFEAB308),
        VoiceModerationTargetColor.red => const Color(0xFFEF4444),
        VoiceModerationTargetColor.black => const Color(0xFF1A1A1A),
      };

  static bool isActionable(VoiceModerationTargetColor c) =>
      c == VoiceModerationTargetColor.green ||
      c == VoiceModerationTargetColor.yellow;
}
