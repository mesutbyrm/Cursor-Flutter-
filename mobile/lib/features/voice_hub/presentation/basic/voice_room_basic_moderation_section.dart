import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_ui_provider.dart';
import '../sheets/voice_room_moderation_sheet.dart';
import '../sheets/voice_room_sheets.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_glass.dart';
import '../widgets/premium_2026/voice_web_owner_stage.dart';
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
  });

  final VoiceRoomEntity room;
  final String liveKey;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final UserEntity? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(voiceRoomUiProvider);
    final onStage = voiceWebOnStageIds(room: room, presence: live.presence);
    final selfOnStage = user != null && onStage.contains(user!.id);
    final canRequestSpeak = user != null &&
        !selfOnStage &&
        !perms.canAssignSeats &&
        !perms.canTakeSeat;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (perms.canModerate || perms.isRoomOwner || perms.isSiteAdmin)
          VoiceRoomBasicModerationBar(
            room: room,
            liveKey: liveKey,
            live: live,
            perms: perms,
          ),
        VoiceWebOwnerStage(
          room: room,
          presence: live.presence,
          djUserIds: live.dj.djUsers.map((u) => u.id).toList(),
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
        ),
        if (canRequestSpeak) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilledButton.tonalIcon(
              onPressed: () => unawaited(
                requestVoiceRoomBasicSpeak(
                  context: context,
                  ref: ref,
                  liveKey: liveKey,
                  pending: ui.requestSpeakPending,
                ),
              ),
              icon: Icon(
                ui.requestSpeakPending
                    ? Icons.hourglass_top_rounded
                    : Icons.record_voice_over_outlined,
              ),
              label: Text(
                ui.requestSpeakPending
                    ? 'Konuşma isteği bekliyor…'
                    : 'Konuşma iste',
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Yetkili moderasyon kısayolları — oda susturma, rol rozeti.
class VoiceRoomBasicModerationBar extends ConsumerWidget {
  const VoiceRoomBasicModerationBar({
    super.key,
    required this.room,
    required this.liveKey,
    required this.live,
    required this.perms,
  });

  final VoiceRoomEntity room;
  final String liveKey;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleLabel = _roleLabel(perms);
    final canRoomMute = perms.canMuteRoom || perms.isRoomOwner || perms.isSiteAdmin;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (roleLabel != null)
            Chip(
              avatar: Icon(
                _roleIcon(perms),
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(roleLabel),
              visualDensity: VisualDensity.compact,
            ),
          if (canRoomMute)
            ActionChip(
              avatar: Icon(
                live.roomMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                size: 16,
              ),
              label: Text(live.roomMuted ? 'Oda sesini aç' : 'Odayı sustur'),
              onPressed: () => unawaited(
                _toggleRoomMute(context, ref),
              ),
            ),
        ],
      ),
    );
  }

  String? _roleLabel(VoiceRoomPermissions p) {
    if (p.isSiteAdmin) return 'Admin';
    if (p.isRoomOwner) return 'Oda sahibi';
    if (p.canBanUsers) return 'Yetkili (&)';
    if (p.canModerate) return 'Moderatör';
    return null;
  }

  IconData _roleIcon(VoiceRoomPermissions p) {
    if (p.isSiteAdmin) return Icons.admin_panel_settings_rounded;
    if (p.isRoomOwner) return Icons.star_rounded;
    if (p.canBanUsers) return Icons.verified_user_rounded;
    return Icons.shield_rounded;
  }

  Future<void> _toggleRoomMute(BuildContext context, WidgetRef ref) async {
    final mute = !live.roomMuted;
    final err = await ref
        .read(voiceRoomLiveProvider(liveKey).notifier)
        .toggleRoomMute(mute: mute);
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mute ? 'Oda susturuldu' : 'Oda sesi açıldı'),
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
    return;
  }
  await requestVoiceRoomBasicSpeak(
    context: context,
    ref: ref,
    liveKey: liveKey,
    pending: ref.read(voiceRoomUiProvider).requestSpeakPending,
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
}) async {
  final self = ref.read(authControllerProvider).valueOrNull;
  final ctrl = ref.read(voiceRoomLiveProvider(liveKey).notifier);
  final onStage = voiceWebOnStageIds(room: room, presence: live.presence);
  final candidates = live.presence
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
            'Koltuk $seatIndex — sahne yönetimi',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (self != null)
            ListTile(
              leading: const Icon(Icons.event_seat_rounded),
              title: const Text('Bu koltuğa otur'),
              onTap: () async {
                Navigator.pop(ctx);
                final err = await ctrl.assignSeat(seatIndex: seatIndex);
                if (context.mounted && err != null) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err)));
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
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err)));
                }
              },
            ),
          ...candidates.map(
            (p) => ListTile(
              leading: CircleAvatar(
                backgroundImage: p.image != null && p.image!.isNotEmpty
                    ? CachedNetworkImageProvider(p.image!)
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
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err)));
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
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
