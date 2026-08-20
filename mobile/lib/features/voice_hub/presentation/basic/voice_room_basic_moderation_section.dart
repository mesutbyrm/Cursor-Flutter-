import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/navigation/wallet_navigation.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_seat_slot.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_ui_provider.dart';
import '../sheets/voice_room_moderation_sheet.dart';
import '../sheets/voice_room_sheets.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_glass.dart';
import '../widgets/premium_2026/voice_web_owner_stage.dart';
import '../widgets/premium_2026/voice_pk_invite_banner.dart';
import '../widgets/premium_2026/voice_gift_announcement_ticker.dart';
import '../widgets/voice_room/voice_room_duyuru_ticker.dart';
import '../widgets/voice_room/voice_room_staff_join_banner.dart';
import 'voice_room_basic_premium_section.dart';

/// Sahne, moderasyon araç çubuğu ve konuşma isteği — temel mod (web parity).
class VoiceRoomBasicModerationSection extends ConsumerWidget {
  const VoiceRoomBasicModerationSection({
    super.key,
    required this.room,
    required this.liveKey,
    required this.live,
    required this.perms,
    required this.user,
    this.isMicMuted = true,
  });

  final VoiceRoomEntity room;
  final String liveKey;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final UserEntity? user;
  final bool isMicMuted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speakingIds = <String>{
      for (final p in live.presence)
        if (p.isSpeaking) p.id,
    };
    if (!isMicMuted && user?.id != null) speakingIds.add(user!.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VoicePkInviteBanner(
          room: room,
          liveKey: liveKey,
          isOwner: perms.isRoomOwner || perms.isSiteAdmin,
        ),
        VoiceWebOwnerStage(
          room: room,
          presence: live.presence,
          seatSlots: live.seatSlots,
          djUserIds: live.dj.djUsers.map((u) => u.id).toList(),
          speakingUserIds: speakingIds,
          selfUserId: user?.id,
          onSeatTap: (seatIndex, occupant) => unawaited(
            onVoiceRoomBasicSeatTap(
              context: context,
              ref: ref,
              room: room,
              liveKey: liveKey,
              live: live,
              perms: perms,
              internalSeatIndex: seatIndex,
              occupant: occupant,
            ),
          ),
          onSeatLongPress: (seatIndex) => unawaited(
            onVoiceRoomBasicSeatLongPress(
              context: context,
              ref: ref,
              room: room,
              liveKey: liveKey,
              live: live,
              perms: perms,
              internalSeatIndex: seatIndex,
            ),
          ),
        ),
        VoiceRoomStaffJoinBanner(
          enterBanner: live.enterBanner,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: const VoiceGiftAnnouncementTicker(),
        ),
        if (live.moderatorAnnouncement?.trim().isNotEmpty == true)
          VoiceRoomDuyuruTicker(
            key: ValueKey(live.moderatorAnnouncement),
            text: live.moderatorAnnouncement!,
            onScrollComplete: () => ref
                .read(voiceRoomLiveProvider(liveKey).notifier)
                .clearModeratorAnnouncement(),
          ),
      ],
    );
  }
}

/// Kullanıcı profili veya moderasyon paneli.
void openVoiceRoomBasicUser(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required String liveKey,
  required ChatRoomPresence user,
  VoiceRoomPermissions? perms,
}) {
  final auth = ref.read(authControllerProvider).valueOrNull;
  final liveState = ref.read(voiceRoomLiveProvider(liveKey));
  ChatRoomPresence? selfPresence;
  if (auth != null) {
    for (final p in liveState.presence) {
      if (p.id == auth.id) {
        selfPresence = p;
        break;
      }
    }
  }
  final permissions = perms ??
      VoiceRoomPermissions.forUser(
        user: auth,
        room: room,
        selfPresence: selfPresence,
        server: liveState.serverPermissions,
      );
  final isOwner = permissions.isRoomOwner || permissions.isSiteAdmin;

  if (permissions.canModerate || isOwner) {
    if (auth != null && user.id == auth.id) {
      showVoiceUserProfileSheet(context, user: user);
      return;
    }
    final djIds = liveState.dj.djUsers.map((u) => u.id).toSet();
    void openGift() => openVoiceRoomBasicGiftShop(
          context,
          ref,
          room: room,
          presence: liveState.presence,
          receiver: user,
        );
    showVoiceRoomModerationSheet(
      context: context,
      ref: ref,
      room: room,
      targetUser: VoiceRoomModerationTarget.fromPresence(user),
      isOwnerOrMod: true,
      perms: permissions,
      isOwner: isOwner,
      isTargetDj: djIds.contains(user.id),
      onGift: openGift,
    );
    return;
  }

  void openGift() => openVoiceRoomBasicGiftShop(
        context,
        ref,
        room: room,
        presence: liveState.presence,
        receiver: user,
      );
  showVoiceUserProfileSheet(
    context,
    user: user,
    onGift: openGift,
  );
}

Future<void> onVoiceRoomBasicSeatTap({
  required BuildContext context,
  required WidgetRef ref,
  required VoiceRoomEntity room,
  required String liveKey,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required int internalSeatIndex,
  ChatRoomPresence? occupant,
}) async {
  if (occupant != null) {
    openVoiceRoomBasicUser(
      context,
      ref,
      room: room,
      liveKey: liveKey,
      user: occupant,
      perms: perms,
    );
    return;
  }
  VoiceRoomSeatSlot? slot;
  for (final s in live.seatSlots) {
    if (s.index == internalSeatIndex) {
      slot = s;
      break;
    }
  }
  if (slot?.isLocked == true && !perms.canAssignSeats) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu koltuk kilitli')),
      );
    }
    return;
  }
  if (perms.canAssignSeats) {
    await showVoiceRoomBasicAssignSeatSheet(
      context: context,
      ref: ref,
      room: room,
      liveKey: liveKey,
      live: live,
      seatIndex: internalSeatIndex,
      perms: perms,
    );
    return;
  }
  if (perms.canTakeSeat) {
    final err = await ref
        .read(voiceRoomLiveProvider(liveKey).notifier)
        .assignSeat(seatIndex: internalSeatIndex);
    if (!context.mounted) return;
    if (err != null) {
      showJetonAwareError(context, err, ref: ref);
    }
    return;
  }
}

Future<void> onVoiceRoomBasicSeatLongPress({
  required BuildContext context,
  required WidgetRef ref,
  required VoiceRoomEntity room,
  required String liveKey,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required int internalSeatIndex,
}) async {
  if (!perms.canAssignSeats) return;
  await showVoiceRoomBasicAssignSeatSheet(
    context: context,
    ref: ref,
    room: room,
    liveKey: liveKey,
    live: live,
    seatIndex: internalSeatIndex,
    perms: perms,
    showAllMembers: true,
  );
}

Future<void> showVoiceRoomBasicAssignSeatSheet({
  required BuildContext context,
  required WidgetRef ref,
  required VoiceRoomEntity room,
  required String liveKey,
  required VoiceRoomLiveState live,
  required int seatIndex,
  required VoiceRoomPermissions perms,
  bool showAllMembers = false,
}) async {
  final self = ref.read(authControllerProvider).valueOrNull;
  final ctrl = ref.read(voiceRoomLiveProvider(liveKey).notifier);
  final onStage = voiceBackendSeatedIds(live.presence);
  VoiceRoomSeatSlot? seatSlot;
  for (final s in live.seatSlots) {
    if (s.index == seatIndex) {
      seatSlot = s;
      break;
    }
  }
  final candidates = showAllMembers
      ? List<ChatRoomPresence>.from(live.presence)
      : live.presence
          .where((p) => !onStage.contains(p.id) || p.seatIndex == seatIndex)
          .toList();
  final canManageDj = perms.isRoomOwner ||
      perms.isSiteAdmin ||
      perms.canManageDj ||
      perms.canManageRoom;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => VoiceGlass(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            showAllMembers
                ? 'Koltuk $seatIndex — sahne yönetimi'
                : 'Koltuk $seatIndex — sahne yönetimi',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (perms.canAssignSeats) ...[
            if (seatSlot != null && !seatSlot.isEmpty)
              ListTile(
                leading: const Icon(Icons.person_off_rounded, color: Colors.orange),
                title: Text('${seatSlot.name ?? 'Kullanıcı'} koltuktan at'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final err = await ctrl.kickFromSeat(seatIndex: seatIndex);
                  if (context.mounted && err != null) {
                    showJetonAwareError(context, err, ref: ref);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.lock_rounded, color: Colors.amber),
              title: Text(
                seatSlot?.isLocked == true ? 'Kilidi aç' : 'Koltuğu kilitle',
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final err = seatSlot?.isLocked == true
                    ? await ctrl.unlockSeat(seatIndex: seatIndex)
                    : await ctrl.lockSeat(seatIndex: seatIndex);
                if (context.mounted && err != null) {
                  showJetonAwareError(context, err, ref: ref);
                }
              },
            ),
          ],
          if (self != null)
            ListTile(
              leading: const Icon(Icons.event_seat_rounded),
              title: const Text('Bu koltuğa otur'),
              onTap: () async {
                Navigator.pop(ctx);
                final err = await ctrl.assignSeat(seatIndex: seatIndex);
                if (context.mounted && err != null) {
                  showJetonAwareError(context, err, ref: ref);
                }
              },
            ),
          if (canManageDj && self != null)
            ListTile(
              leading: const Icon(Icons.headphones_rounded),
              title: const Text('Kendimi DJ yap'),
              onTap: () async {
                Navigator.pop(ctx);
                final err = await ctrl.addRoomDj(self.id);
                if (context.mounted && err != null) {
                  showJetonAwareError(context, err, ref: ref);
                }
              },
            ),
          ...candidates.map(
            (p) => ListTile(
              leading: CircleAvatar(
                backgroundImage: p.image != null && p.image!.isNotEmpty
                    ? canlifalImageProvider(p.image!)
                    : null,
                child: p.image == null || p.image!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(p.displayName),
              subtitle: _roleSubtitle(p) == null
                  ? null
                  : Text(_roleSubtitle(p)!),
              trailing: canManageDj
                  ? IconButton(
                      icon: const Icon(Icons.headphones_rounded, size: 20),
                      tooltip: 'DJ yap',
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final err = await ctrl.addRoomDj(p.id);
                        if (context.mounted && err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                        }
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
                      tooltip: 'Moderasyon',
                      onPressed: () {
                        Navigator.pop(ctx);
                        openVoiceRoomBasicUser(
                          context,
                          ref,
                          room: room,
                          liveKey: liveKey,
                          user: p,
                          perms: perms,
                        );
                      },
                    ),
              onTap: () async {
                Navigator.pop(ctx);
                final err = await ctrl.assignSeat(
                  seatIndex: seatIndex,
                  userId: p.id,
                );
                if (context.mounted && err != null) {
                  showJetonAwareError(context, err, ref: ref);
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}

String? _roleSubtitle(ChatRoomPresence p) {
  final role = (p.chatRole ?? '').toLowerCase();
  final symbol = p.roleSymbol?.trim();
  if (role == 'owner' || symbol == '~') return 'Oda sahibi';
  if (role == 'admin' || role == 'superadmin') return 'Admin';
  if (role == 'moderator' || role == 'mod' || symbol == '@') return 'Moderatör';
  if (role == 'sop' || symbol == '&') return 'Yetkili';
  if (p.seatIndex != null || role == 'voice' || symbol == '+') return 'Konuşmacı';
  return null;
}

Future<void> requestVoiceRoomBasicSpeak({
  required BuildContext context,
  required WidgetRef ref,
  required String liveKey,
  required bool pending,
}) async {
  final liveCtrl = ref.read(voiceRoomLiveProvider(liveKey).notifier);
  final err = pending
      ? await liveCtrl.cancelSpeakRequest()
      : await liveCtrl.requestSpeak();
  if (!context.mounted) return;
  if (err != null) {
    showJetonAwareError(context, err, ref: ref);
    return;
  }
  showVoiceRequestSpeakSheet(
    context,
    ref,
    pending: ref.read(voiceRoomUiProvider).requestSpeakPending,
    onPrimary: () async {
      final ctrl = ref.read(voiceRoomLiveProvider(liveKey).notifier);
      final pendingNow = ref.read(voiceRoomUiProvider).requestSpeakPending;
      final e = pendingNow
          ? await ctrl.cancelSpeakRequest()
          : await ctrl.requestSpeak();
      if (context.mounted && e != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
      }
    },
  );
}
