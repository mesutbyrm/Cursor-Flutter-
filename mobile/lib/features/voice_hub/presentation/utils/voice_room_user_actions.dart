import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../sheets/voice_room_moderation_sheet.dart';
import '../sheets/voice_room_sheets.dart';
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

  /// Chat / koltuk / katılımcı listesi — profil veya moderasyon sheet.
  static void openUserSheet({
    required BuildContext context,
    required WidgetRef ref,
    required VoiceRoomEntity room,
    required VoiceRoomLiveState liveState,
    required ChatRoomPresence user,
    required VoiceRoomPermissions permissions,
    required bool isOwner,
    required String? selfId,
    required VoidCallback onGift,
  }) {
    if (shouldOpenSelfProfile(
      perms: permissions,
      selfId: selfId,
      target: user,
    )) {
      showVoiceUserProfileSheet(context, user: user, onGift: onGift);
      return;
    }

    if (canOpenModerationSheet(permissions)) {
      final djIds = liveState.dj.djUsers.map((u) => u.id).toSet();
      showVoiceRoomModerationSheet(
        context: context,
        ref: ref,
        room: room,
        targetUser: VoiceRoomModerationTarget.fromPresence(user),
        isOwnerOrMod: true,
        perms: permissions,
        isOwner: isOwner || permissions.isRoomOwner,
        isTargetDj: djIds.contains(user.id),
        onGift: onGift,
      );
      return;
    }

    showVoiceUserProfileSheet(context, user: user, onGift: onGift);
  }
}
