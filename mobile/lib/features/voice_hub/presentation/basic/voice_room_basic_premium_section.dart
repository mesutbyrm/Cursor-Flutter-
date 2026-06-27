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
import '../sheets/voice_room_hub_settings.dart';
import '../sheets/voice_room_sheets.dart';
import '../sheets/voice_youtube_song_sheet.dart';
import '../theme/voice_room_tokens.dart';
import '../utils/voice_music_access.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_neon_avatar.dart';
import '../widgets/voice_room/voice_room_music_mini_player.dart';
import '../widgets/premium_2026/voice_web_owner_stage.dart';
import 'voice_room_basic_moderation_section.dart';

/// Çark menüsü — PK, efekt, tema, moderasyon, DJ, !istek.
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
  final pk = ref.read(pkBattleRemoteProvider);
  final pkActive = pk != null && !pk.isEnded;
  final authUser = user ?? ref.read(authControllerProvider).valueOrNull;
  final dj = live.dj;
  final jeton = VoiceMusicAccess.jetonFromBalances(
    ref.read(walletBalancesProvider).valueOrNull,
  );
  final isDj = authUser != null &&
      (room.djUserIds.contains(authUser.id) ||
          dj.djUsers.any((u) => u.id == authUser.id));
  final showDjHub = VoiceMusicAccess.canShowDjMusicPanel(
    perms: perms,
    isDj: isDj,
  );
  final canRequest = VoiceMusicAccess.canRequestSongs(
    dj: dj,
    perms: perms,
    jetonBalance: jeton,
  );
  final canRoomMute =
      perms.canMuteRoom || perms.isRoomOwner || perms.isSiteAdmin;
  final roleLabel = _roleLabel(perms);
  final onStage = voiceWebOnStageIds(room: room, presence: live.presence);
  final selfOnStage = authUser != null && onStage.contains(authUser.id);
  final canRequestSpeak = authUser != null &&
      !selfOnStage &&
      !perms.canAssignSeats &&
      !perms.canTakeSeat;
  final ui = ref.read(voiceRoomUiProvider);

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF14101F),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            if (roleLabel != null)
              ListTile(
                leading: Icon(_roleIcon(perms)),
                title: Text(roleLabel),
                subtitle: const Text('Oda yetkiniz'),
              ),
            ListTile(
              leading: Icon(
                pkActive ? Icons.flash_on_rounded : Icons.sports_mma_rounded,
                color: VoiceRoomTokens.neonPink,
              ),
              title: Text(pkActive ? 'PK savaşı (aktif)' : 'PK daveti gönder'),
              onTap: () {
                Navigator.pop(ctx);
                if (pkActive) {
                  final key =
                      room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
                  context.push('/voice-room/$key/pk', extra: room);
                } else {
                  onPk();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_rounded),
              title: const Text('Ses efektleri'),
              onTap: () {
                Navigator.pop(ctx);
                showVoiceEffectsSheet(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper_rounded),
              title: const Text('Oda teması'),
              onTap: () {
                Navigator.pop(ctx);
                showVoiceRoomHubSettingsSheet(
                  context,
                  ref,
                  room: room,
                  live: live,
                  perms: perms,
                  isOwner: isOwner,
                  onUserTap: onOpenUser,
                );
              },
            ),
            if (canRoomMute)
              ListTile(
                leading: Icon(
                  live.roomMuted
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_rounded,
                ),
                title: Text(
                  live.roomMuted ? 'Oda sesini aç' : 'Odayı sustur',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final mute = !live.roomMuted;
                  final err = await ref
                      .read(voiceRoomLiveProvider(liveKey).notifier)
                      .toggleRoomMute(mute: mute);
                  if (!context.mounted) return;
                  if (err != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  }
                },
              ),
            if (canRequestSpeak)
              ListTile(
                leading: Icon(
                  ui.requestSpeakPending
                      ? Icons.hourglass_top_rounded
                      : Icons.record_voice_over_outlined,
                ),
                title: Text(
                  ui.requestSpeakPending
                      ? 'Konuşma isteği bekliyor'
                      : 'Konuşma iste',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(
                    requestVoiceRoomBasicSpeak(
                      context: context,
                      ref: ref,
                      liveKey: liveKey,
                      pending: ui.requestSpeakPending,
                    ),
                  );
                },
              ),
            if (showDjHub)
              ListTile(
                leading: const Icon(Icons.headphones_rounded),
                title: const Text('DJ paneli'),
                onTap: () {
                  Navigator.pop(ctx);
                  showVoiceMusicControlHub(
                    context,
                    ref,
                    room: room,
                    perms: perms,
                  );
                },
              ),
            if (canRequest || dj.musicEnabled)
              ListTile(
                leading: const Icon(Icons.music_note_rounded),
                title: const Text('Şarkı iste (!istek)'),
                onTap: () {
                  Navigator.pop(ctx);
                  showVoiceYoutubeSongSheet(
                    context,
                    ref,
                    room: room,
                    perms: perms,
                  );
                },
              ),
            if (dj.musicQueue.isNotEmpty || dj.nowPlaying != null)
              ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: Text('Müzik kuyruğu (${dj.musicQueue.length})'),
                onTap: () {
                  Navigator.pop(ctx);
                  showRoomMusicQueueSheet(
                    context,
                    ref,
                    liveKey: liveKey,
                    dj: dj,
                    canControlMusic: canControlMusic,
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.people_outline_rounded),
              title: const Text('Katılımcı listesi'),
              onTap: () {
                Navigator.pop(ctx);
                showVoiceSpeakerListSheet(
                  context,
                  presence: live.presence,
                  room: room,
                  onUserTap: onOpenUser,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Odayı paylaş'),
              onTap: () {
                Navigator.pop(ctx);
                shareVoiceRoom(context, room);
              },
            ),
            if (canRequest || dj.musicEnabled) ...[
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: istekCtrl,
                        decoration: const InputDecoration(
                          hintText: '!istek Sanatçı - Şarkı',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          onSendIstek();
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        onSendIstek();
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        return _ChatLine(message: visible[index]);
      },
    );
  }
}

/// Sabit mesaj çubuğu — klavye üstünde.
class VoiceRoomBasicMessageBar extends StatelessWidget {
  const VoiceRoomBasicMessageBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onEmoji,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onEmoji;

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
            onPressed: onEmoji,
            icon: const Icon(Icons.emoji_emotions_outlined, size: 22),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Mesaj yaz…',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onSend,
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
    final jeton = VoiceMusicAccess.jetonFromBalances(
      ref.watch(walletBalancesProvider).valueOrNull,
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

class _ChatLine extends StatelessWidget {
  const _ChatLine({required this.message});

  final ChatRoomMessage message;

  @override
  Widget build(BuildContext context) {
    final name = message.user?.displayName?.trim().isNotEmpty == true
        ? message.user!.displayName!.trim()
        : (message.user?.name ?? 'Biri');
    if (message.kind == ChatMessageKind.gift) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          '$name ${message.giftEmoji ?? '🎁'} hediye gönderdi',
          style: const TextStyle(fontSize: 13, color: VoiceRoomTokens.gold),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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

/// Müzik çalarken ince mini player (isteğe bağlı üst bant).
class VoiceRoomBasicFloatingMiniPlayer extends ConsumerWidget {
  const VoiceRoomBasicFloatingMiniPlayer({
    super.key,
    required this.room,
    required this.liveKey,
    required this.live,
    required this.canControlMusic,
    required this.perms,
  });

  final VoiceRoomEntity room;
  final String liveKey;
  final VoiceRoomLiveState live;
  final bool canControlMusic;
  final VoiceRoomPermissions perms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dj = live.dj;
    final ui = ref.watch(voiceRoomUiProvider);
    final musicSession = ref.watch(voiceRoomMusicSessionProvider);
    final show = (dj.playing || dj.nowPlaying != null) &&
        !musicSession.dismissed &&
        !musicSession.userDismissedPlayer;
    if (!show) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: VoiceRoomMusicMiniPlayer(
        dj: dj,
        canControl: canControlMusic,
        canModerate: canControlMusic,
        musicMuted: !ui.backgroundMusicEnabled,
        showClose: true,
        onPlayPause: () async {
          final notifier = ref.read(voiceRoomLiveProvider(liveKey).notifier);
          if (dj.playing) {
            await notifier.pauseMusic();
          } else {
            await notifier.resumeMusic();
          }
        },
        onSkip: canControlMusic
            ? () => ref.read(voiceRoomLiveProvider(liveKey).notifier).skipMusic()
            : null,
        onStop: canControlMusic
            ? () => ref.read(voiceRoomLiveProvider(liveKey).notifier).stopMusic()
            : null,
        onMuteToggle: () =>
            ref.read(voiceRoomUiProvider.notifier).toggleBackgroundMusic(),
        onClose: () =>
            ref.read(voiceRoomLiveProvider(liveKey).notifier).closeMusicPlayer(),
        onTap: () => showRoomMusicQueueSheet(
          context,
          ref,
          liveKey: liveKey,
          dj: dj,
          canControlMusic: canControlMusic,
        ),
      ),
    );
  }
}
