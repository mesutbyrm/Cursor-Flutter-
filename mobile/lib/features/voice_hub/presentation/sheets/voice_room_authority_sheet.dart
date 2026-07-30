import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../utils/voice_room_permissions.dart';
import 'voice_room_management_panel.dart';

/// Eski "Yetki Ver" girişi — kullanıcı listesine yönlendirilir.
Future<void> showVoiceRoomAuthoritySheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required bool isOwner,
}) {
  final canOpen = perms.isSiteAdmin ||
      perms.isRoomOwner ||
      perms.canModerate ||
      perms.canManageRoom ||
      perms.canMuteUsers ||
      perms.canKickUsers ||
      perms.canBanUsers;
  if (!canOpen) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yetki yönetimi için yetkiniz yok')),
    );
    return Future.value();
  }

  return showVoiceRoomManagementPanel(
    context,
    ref,
    room: room,
    live: live,
    perms: perms,
    isOwner: isOwner,
    initial: VoiceMgmtInitial.users,
  );
}
