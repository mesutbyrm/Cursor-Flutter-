import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/config/env.dart';
import '../../../../core/navigation/wallet_navigation.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_realtime_event.dart';
import '../../domain/pk/pk_duration_options.dart';
import '../../music/presentation/widgets/room_music_queue_sheet.dart';
import '../providers/chat_room_providers.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_room_ui_provider.dart';
import '../sheets/voice_room_menu_sheet.dart';
import '../sheets/voice_room_sheets.dart';
import '../sheets/voice_youtube_song_sheet.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_music_access.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/chat/chat_message_widgets.dart';
import '../widgets/voice_room/voice_room_mention_text_field.dart';
import '../widgets/premium/voice_neon_avatar.dart';
import '../widgets/voice_room/voice_room_premium_music_card.dart';
import '../widgets/premium_2026/voice_web_owner_stage.dart';
import 'voice_room_basic_moderation_section.dart';

/// Çark menüsü — Faz 3 menüsüne yönlendirir (geriye uyumluluk).
Future<void> showVoiceRoomBasicToolsSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required String liveKey,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
  required bool isOwner,
  required VoidCallback onPk,
  required void Function(ChatRoomPresence user) onOpenUser,
  required VoidCallback onSendIstek,
  required TextEditingController istekCtrl,
  required bool canControlMusic,
  UserEntity? user,
}) {
  return showVoiceRoomMenuSheet(
    context,
    ref,
    room: room,
    live: live,
    perms: perms,
    isOwner: isOwner,
    onUserTap: onOpenUser,
    onPkInvite: onPk,
  );
}

/// Koltukların altında — yalnızca odaya girişler (açılır/kapanır, kayan yazı).
class VoiceRoomBasicJoinTicker extends StatefulWidget {
  const VoiceRoomBasicJoinTicker({
    super.key,
    required this.events,
    required this.messages,
    required this.onlineCount,
  });

  final List<VoiceRoomRealtimeEvent> events;
  final List<ChatRoomMessage> messages;
  final int onlineCount;

  @override
  State<VoiceRoomBasicJoinTicker> createState() =>
      _VoiceRoomBasicJoinTickerState();
}

class _VoiceRoomBasicJoinTickerState extends State<VoiceRoomBasicJoinTicker> {
  final _scrollCtrl = ScrollController();
  Timer? _marqueeTimer;

  @override
  void initState() {
    super.initState();
    _marqueeTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      if (max <= 0) return;
      final next = _scrollCtrl.offset + 1.2;
      _scrollCtrl.jumpTo(next > max ? 0 : next);
    });
  }

  @override
  void dispose() {
    _marqueeTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<String> _joinLines() {
    final lines = <String>[];
    for (final m in widget.messages) {
      if (m.kind == ChatMessageKind.systemJoin &&
          m.content.trim().isNotEmpty) {
        lines.add(m.content.trim());
      }
    }
    for (final e in widget.events) {
      if (e.kind == VoiceRoomRealtimeKind.join && e.message.trim().isNotEmpty) {
        lines.add(e.message.trim());
      }
    }
    return lines.reversed.take(12).toList().reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final lines = _joinLines();
    final text = lines.isEmpty
        ? 'Odaya girenler burada görünür…'
        : lines.join('   •   ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 4),
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: true,
          visualDensity: VisualDensity.compact,
          title: Text(
            'Odada ${widget.onlineCount}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          subtitle: lines.isEmpty
              ? null
              : Text(
                  lines.last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
          children: [
            SizedBox(
              height: 28,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sohbet akışı — kaydırılabilir mesaj listesi.
class VoiceRoomBasicChatFeed extends StatelessWidget {
  const VoiceRoomBasicChatFeed({super.key, required this.messages});

  final List<ChatRoomMessage> messages;

  @override
  Widget build(BuildContext context) {
    final visible = messages
        .where(
          (m) =>
              m.kind == ChatMessageKind.text ||
              m.kind == ChatMessageKind.gift,
        )
        .toList();
    if (visible.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sohbet mesajları burada görünür.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final msg = visible[visible.length - 1 - index];
        return ChatMessageWidget(
          key: ValueKey(msg.id),
          message: msg,
        );
      },
    );
  }
}

/// Sabit mesaj çubuğu — klavye üstünde.
class VoiceRoomBasicMessageBar extends StatefulWidget {
  const VoiceRoomBasicMessageBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onEmoji,
    this.onChanged,
    this.presence = const [],
    this.selfUserId,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onEmoji;
  final ValueChanged<String>? onChanged;
  final List<ChatRoomPresence> presence;
  final String? selfUserId;

  @override
  State<VoiceRoomBasicMessageBar> createState() => _VoiceRoomBasicMessageBarState();
}

class _VoiceRoomBasicMessageBarState extends State<VoiceRoomBasicMessageBar> {
  late final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: widget.onEmoji,
            icon: const Icon(Icons.emoji_emotions_outlined, size: 22),
          ),
          Expanded(
            child: VoiceRoomMentionTextField(
              controller: widget.controller,
              focusNode: _focusNode,
              presence: widget.presence,
              excludeUserId: widget.selfUserId,
              onChanged: widget.onChanged,
              onSubmitted: (_) => widget.onSend(),
              hintText: 'Mesaj yaz…',
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Mesaj yaz…',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: widget.onSend,
            icon: const Icon(Icons.send_rounded, size: 22),
          ),
        ],
      ),
    );
  }
}

/// Kompakt alt kontrol — mic, hoparlör, jeton, çık.
class VoiceRoomBasicCompactControls extends ConsumerWidget {
  const VoiceRoomBasicCompactControls({
    super.key,
    required this.isMicMuted,
    required this.speakerOn,
    required this.onMic,
    required this.onSpeaker,
    required this.onLeave,
  });

  final bool isMicMuted;
  final bool speakerOn;
  final VoidCallback onMic;
  final VoidCallback onSpeaker;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jeton = ref.watch(
      walletBalancesProvider.select((a) => a.valueOrNull?.jeton ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Row(
        children: [
          _MiniBtn(
            icon: isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: 'Mic',
            active: !isMicMuted,
            onTap: onMic,
          ),
          const SizedBox(width: 6),
          _MiniBtn(
            icon: speakerOn
                ? Icons.volume_up_rounded
                : Icons.hearing_disabled_rounded,
            label: 'Ses',
            active: speakerOn,
            onTap: onSpeaker,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Material(
              color: VoiceRoomTokens.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => openJetonStore(context, ref: ref),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on_rounded,
                          size: 16, color: VoiceRoomTokens.gold),
                      const SizedBox(width: 4),
                      Text(
                        '$jeton',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _MiniBtn(
            icon: Icons.logout_rounded,
            label: 'Çık',
            danger: true,
            onTap: onLeave,
          ),
        ],
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  const _MiniBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = danger
        ? scheme.errorContainer
        : active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              Text(label, style: const TextStyle(fontSize: 9)),
            ],
          ),
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
    await context.push('/voice-room/$key/pk-invite', extra: room);
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

/// Müzik çalarken koltuk altı premium kart (web parity).
class VoiceRoomBasicFloatingMiniPlayer extends ConsumerWidget {
  const VoiceRoomBasicFloatingMiniPlayer({
    super.key,
    required this.room,
    required this.liveKey,
    required this.live,
    required this.canControlMusic,
    required this.canCloseMusic,
    required this.perms,
  });

  final VoiceRoomEntity room;
  final String liveKey;
  final VoiceRoomLiveState live;
  final bool canControlMusic;
  final bool canCloseMusic;
  final VoiceRoomPermissions perms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dj = live.dj;
    final musicSession = ref.watch(voiceRoomMusicSessionProvider);
    final show = (dj.playing || dj.nowPlaying != null || dj.musicQueue.isNotEmpty) &&
        !musicSession.dismissed &&
        !musicSession.userDismissedPlayer;
    if (!show) return const SizedBox.shrink();

    return VoiceRoomPremiumMusicCard(
      room: room,
      liveKey: liveKey,
      dj: dj,
      canClose: canCloseMusic,
      listenerCount: live.onlineCountFor(room),
      likeCount: live.musicLikeCount,
      onQueueTap: () => showRoomMusicQueueSheet(
        context,
        ref,
        liveKey: liveKey,
        dj: dj,
        canControlMusic: canControlMusic,
        canStopMusic: canCloseMusic,
      ),
    );
  }
}
