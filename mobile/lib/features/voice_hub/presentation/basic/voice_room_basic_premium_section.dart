import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_room_ui_provider.dart';
import '../sheets/voice_room_hub_settings.dart';
import '../sheets/voice_room_sheets.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_neon_avatar.dart';
import '../../domain/pk/pk_duration_options.dart';

/// Premium kısayol çubuğu — hediye, PK, efekt, tema, ayarlar.
class VoiceRoomBasicPremiumToolbar extends ConsumerWidget {
  const VoiceRoomBasicPremiumToolbar({
    super.key,
    required this.room,
    required this.liveKey,
    required this.live,
    required this.perms,
    required this.isOwner,
    required this.onGift,
    required this.onPk,
    required this.onOpenUser,
  });

  final VoiceRoomEntity room;
  final String liveKey;
  final VoiceRoomLiveState live;
  final VoiceRoomPermissions perms;
  final bool isOwner;
  final VoidCallback onGift;
  final VoidCallback onPk;
  final void Function(ChatRoomPresence user) onOpenUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pk = ref.watch(pkBattleRemoteProvider);
    final pkActive = pk != null && !pk.isEnded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ChipButton(
              icon: Icons.card_giftcard_rounded,
              label: 'Hediye',
              color: VoiceRoomTokens.gold,
              onTap: onGift,
            ),
            const SizedBox(width: 8),
            _ChipButton(
              icon: pkActive ? Icons.flash_on_rounded : Icons.sports_mma_rounded,
              label: pkActive ? 'PK (aktif)' : 'PK',
              color: VoiceRoomTokens.neonPink,
              onTap: pkActive
                  ? () => context.push(
                        '/voice-room/${room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id}/pk',
                        extra: room,
                      )
                  : onPk,
            ),
            const SizedBox(width: 8),
            _ChipButton(
              icon: Icons.auto_awesome_rounded,
              label: 'Efekt',
              onTap: () => showVoiceEffectsSheet(context, ref),
            ),
            const SizedBox(width: 8),
            _ChipButton(
              icon: Icons.wallpaper_rounded,
              label: 'Tema',
              onTap: () => showVoiceRoomHubSettingsSheet(
                context,
                ref,
                room: room,
                live: live,
                perms: perms,
                isOwner: isOwner,
                onUserTap: onOpenUser,
              ),
            ),
            const SizedBox(width: 8),
            _ChipButton(
              icon: Icons.more_horiz_rounded,
              label: 'Daha',
              onTap: () => showVoiceMoreMenuSheet(
                context,
                ref: ref,
                room: room,
                live: live,
                perms: perms,
                onSettings: () => showVoiceRoomHubSettingsSheet(
                  context,
                  ref,
                  room: room,
                  live: live,
                  perms: perms,
                  isOwner: isOwner,
                  onUserTap: onOpenUser,
                ),
                onSpeakers: () => showVoiceSpeakerListSheet(
                  context,
                  presence: live.presence,
                  room: room,
                  onUserTap: onOpenUser,
                ),
                onShare: () => shareVoiceRoom(context, room),
                onBackgroundMusic: () => ref
                    .read(voiceRoomUiProvider.notifier)
                    .toggleBackgroundMusic(),
                onPickBackground: (perms.canChangeBackground || isOwner)
                    ? () => showVoiceRoomHubSettingsSheet(
                          context,
                          ref,
                          room: room,
                          live: live,
                          perms: perms,
                          isOwner: isOwner,
                          onUserTap: onOpenUser,
                        )
                    : null,
                onPkBattle: onPk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: c),
      label: Text(label),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Sohbet + emoji — mevcut SSE mesaj akışı.
class VoiceRoomBasicChatSection extends StatelessWidget {
  const VoiceRoomBasicChatSection({
    super.key,
    required this.messages,
    required this.messageController,
    required this.onSend,
    required this.onEmoji,
  });

  final List<ChatRoomMessage> messages;
  final TextEditingController messageController;
  final VoidCallback onSend;
  final VoidCallback onEmoji;

  @override
  Widget build(BuildContext context) {
    final visible = messages
        .where(
          (m) =>
              m.kind == ChatMessageKind.text ||
              m.kind == ChatMessageKind.gift ||
              m.kind == ChatMessageKind.systemJoin,
        )
        .toList();
    final recent = visible.length > 8
        ? visible.sublist(visible.length - 8)
        : visible;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sohbet',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          if (recent.isEmpty)
            Text(
              'Mesajlar ve hediyeler burada görünür.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...recent.map((m) => _ChatLine(message: m)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: onEmoji,
                icon: const Icon(Icons.emoji_emotions_outlined),
                tooltip: 'Emoji',
              ),
              Expanded(
                child: TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    hintText: 'Mesaj yaz…',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
              IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded),
                tooltip: 'Gönder',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatLine extends StatelessWidget {
  const _ChatLine({required this.message});

  final ChatRoomMessage message;

  @override
  Widget build(BuildContext context) {
    final name = message.user?.displayName.trim().isNotEmpty == true
        ? message.user!.displayName.trim()
        : (message.user?.name ?? 'Biri');
    if (message.kind == ChatMessageKind.gift) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          '$name ${message.giftEmoji ?? '🎁'} hediye gönderdi',
          style: const TextStyle(fontSize: 13, color: VoiceRoomTokens.gold),
        ),
      );
    }
    if (message.kind == ChatMessageKind.systemJoin) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
          children: [
            TextSpan(
              text: '$name: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: message.content),
          ],
        ),
      ),
    );
  }
}

void showVoiceRoomBasicEmojiPicker(
  BuildContext ctx,
  TextEditingController ctrl,
) {
  const emojis = [
    '😀', '😂', '❤️', '🔥', '👏', '🎉', '💎', '🎤',
    '🙏', '✨', '💜', '😍', '🤣', '👋', '🌙', '⭐',
  ];
  showModalBottomSheet<void>(
    context: ctx,
    backgroundColor: Colors.transparent,
    builder: (sheet) => Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF14101F).withValues(alpha: 0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: emojis
            .map(
              (e) => InkWell(
                onTap: () {
                  ctrl.text = '${ctrl.text}$e';
                  Navigator.pop(sheet);
                },
                child: Text(e, style: const TextStyle(fontSize: 28)),
              ),
            )
            .toList(),
      ),
    ),
  );
}

List<ChatRoomPresence> voiceRoomBasicSeatedUsers(
  List<ChatRoomPresence> presence,
) {
  final seated = presence
      .where((p) => p.seatIndex != null && p.seatIndex! >= 0)
      .toList()
    ..sort((a, b) => (a.seatIndex ?? 99).compareTo(b.seatIndex ?? 99));
  if (seated.isNotEmpty) return seated;
  return presence.where((p) => p.isSpeaking).toList();
}

void openVoiceRoomBasicGiftShop(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required List<ChatRoomPresence> presence,
  ChatRoomPresence? receiver,
}) {
  showPremiumVoiceGiftShop(
    context,
    ref,
    room: room,
    seatedUsers: voiceRoomBasicSeatedUsers(presence),
    initialReceiver: receiver,
  );
}

Future<void> shareVoiceRoom(BuildContext context, VoiceRoomEntity room) async {
  final slug = room.slug;
  final url = '${Env.siteOrigin}/sohbet/$slug';
  final title = room.displayTitle;
  await Share.share(
    'CanlıFal sesli odaya katıl: $title\n$url',
    subject: title,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Oda daveti paylaşıldı')),
  );
}

Future<void> openVoiceRoomBasicPkInvite(
  BuildContext context,
  VoiceRoomEntity room,
) async {
  final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  if (key.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Oda bilgisi yüklenemedi — PK başlatılamadı')),
    );
    return;
  }
  try {
    await context.push('/voice-room/$key/pk-invite', extra: room.stableSessionKey);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ApiException.userMessage(e))),
    );
  }
}

Future<void> connectVoiceRoomBasicPkBattle(
  WidgetRef ref,
  VoiceRoomEntity room,
) async {
  final roomKey = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  if (roomKey.isEmpty) return;
  final remote = ref.read(pkBattleRemoteProvider.notifier);
  await remote.loadRoomBattle(
    roomKey,
    alternateRoomId: room.slug != roomKey ? room.slug : null,
  );
  final battle = ref.read(pkBattleRemoteProvider);
  if (battle == null || battle.isEnded) {
    if (battle != null && battle.isEnded) remote.clear();
    return;
  }
  remote.connectSocket(
    roomId: roomKey,
    alternateRoomId: room.slug != roomKey ? room.slug : null,
    battleId: battle.id,
  );
}

Future<void> showVoiceRoomBasicIncomingPkInvite({
  required BuildContext context,
  required WidgetRef ref,
  required VoiceRoomEntity room,
  required String battleId,
}) async {
  final battle = ref.read(pkBattleRemoteProvider);
  final durationLabel = battle != null
      ? pkDurationBySeconds(battle.durationSeconds).label
      : '3 dakika';
  final accept = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('PK Daveti'),
      content: Text(
        'Bir oda size PK daveti gönderdi.\nSüre: $durationLabel\n\nKabul ediyor musunuz?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Reddet'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Kabul Et'),
        ),
      ],
    ),
  );
  final remote = ref.read(pkBattleRemoteProvider.notifier);
  final roomKey = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  final altRoom = room.slug != roomKey ? room.slug : null;
  if (accept == true) {
    await remote.accept(
      battleId,
      roomId: roomKey,
      alternateRoomId: altRoom,
    );
    if (context.mounted) {
      context.push('/voice-room/$roomKey/pk', extra: room);
    }
  } else if (accept == false) {
    await remote.reject(
      battleId,
      roomId: roomKey,
      alternateRoomId: altRoom,
    );
  }
}

/// Profil kartı — neon avatar + rozet (chatRole).
class VoiceRoomBasicProfilePreview extends StatelessWidget {
  const VoiceRoomBasicProfilePreview({
    super.key,
    required this.user,
    this.onTap,
  });

  final ChatRoomPresence user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            VoiceNeonAvatar(
              url: user.image,
              size: 44,
              speaking: user.isSpeaking,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (user.chatRole != null && user.chatRole!.isNotEmpty)
                    Text(
                      user.chatRole!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
            if (user.roleSymbol != null && user.roleSymbol!.isNotEmpty)
              Chip(
                label: Text(user.roleSymbol!),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}
