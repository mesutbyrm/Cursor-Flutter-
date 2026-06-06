import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_design.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import '../../trtc/presentation/providers/trtc_providers.dart';
import '../../trtc/presentation/trtc_room_manager.dart';
import '../domain/entities/chat_room_message.dart';
import '../domain/entities/chat_room_presence.dart';
import 'pages/voice_music_hub_page.dart';
import 'providers/chat_room_providers.dart';
import 'providers/pk_battle_remote_provider.dart';
import 'sheets/voice_room_sheets.dart';
import 'providers/voice_room_ui_provider.dart';
import 'utils/voice_music_access.dart';
import 'utils/voice_room_permissions.dart';
import 'widgets/voice_room/voice_room_action_row.dart';
import 'widgets/voice_room/voice_room_announcement.dart';
import 'widgets/voice_room/voice_room_bottom_bar.dart';
import 'widgets/voice_room/voice_room_chat_panel.dart';
import 'widgets/voice_room/voice_room_music_mini_player.dart';
import 'widgets/voice_room/voice_room_seats_panel.dart';
import 'widgets/voice_room/voice_room_top_bar.dart';

/// Sesli sohbet odası — web neon düzeni + TRTC ses + native müzik.
class VoiceRoomRtcPage extends ConsumerStatefulWidget {
  const VoiceRoomRtcPage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<VoiceRoomRtcPage> createState() => _VoiceRoomRtcPageState();
}

class _VoiceRoomRtcPageState extends ConsumerState<VoiceRoomRtcPage> {
  final _trtc = TrtcRoomManager();
  final _messageCtrl = TextEditingController();
  var _joining = true;
  var _joined = false;
  String? _error;
  var _micOn = true;
  var _leaving = false;
  var _announcementVisible = true;
  String? _shownPkInviteId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinRoom());
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _trtc.dispose();
    super.dispose();
  }

  VoiceRoomPermissions _permissions(
    VoiceRoomEntity room,
    List<ChatRoomPresence> presence,
  ) {
    final user = ref.read(authControllerProvider).valueOrNull;
    ChatRoomPresence? self;
    if (user != null) {
      for (final p in presence) {
        if (p.id == user.id) {
          self = p;
          break;
        }
      }
    }
    return VoiceRoomPermissions.forUser(
      user: user,
      room: room,
      selfPresence: self,
    );
  }

  Future<void> _joinRoom() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      setState(() {
        _joining = false;
        _error = 'Odaya girmek için giriş yapın';
      });
      return;
    }

    if (!_trtc.isSupported) {
      setState(() {
        _joining = false;
        _error = 'Sesli oda bu platformda desteklenmiyor';
      });
      return;
    }

    try {
      final cred = await ref.read(trtcRemoteProvider).fetchUserSig(
            userId: user.id,
            roomId: widget.room.trtcRoomId.isNotEmpty
                ? widget.room.trtcRoomId
                : widget.room.id,
          );
      await _trtc.join(
        credentials: cred,
        isHost: false,
        audioOnly: true,
      );
      if (mounted) {
        setState(() {
          _joining = false;
          _joined = true;
          _micOn = _trtc.micOn;
        });
        final r = widget.room;
        final roomKey = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
        final remote = ref.read(pkBattleRemoteProvider.notifier);
        await remote.loadRoomBattle(roomKey);
        remote.connectSocket(
          roomId: roomKey,
          alternateRoomId: r.slug != roomKey ? r.slug : null,
          battleId: ref.read(pkBattleRemoteProvider)?.id,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _joining = false;
          _error = ApiException.userMessage(e);
        });
      }
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    ref.read(pkBattleRemoteProvider.notifier).clear();
    await _trtc.leave();
    if (mounted) context.go('/voice-rooms');
  }

  void _shareRoom() {
    final slug = widget.room.slug;
    final url = '${Env.siteOrigin}/sohbet/$slug';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paylaşım linki kopyalandı: $url')),
    );
  }

  void _openPkInvite() {
    final room = widget.room;
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    context.push('/voice-room/$key/pk-invite', extra: room);
  }

  void _openActivePk() {
    final room = widget.room;
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    context.push('/voice-room/$key/pk', extra: room);
  }

  Future<void> _showIncomingPkInvite(String battleId) async {
    if (!mounted) return;
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PK Daveti'),
        content: const Text('Bir oda size PK daveti gönderdi. Kabul ediyor musunuz?'),
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
    if (accept == true) {
      await remote.accept(battleId);
      if (mounted) _openActivePk();
    } else if (accept == false) {
      await remote.reject(battleId);
    }
  }

  String _latestSystemJoin(List<ChatRoomMessage> messages) {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].kind == ChatMessageKind.systemJoin) {
        return messages[i].content;
      }
    }
    final owner = widget.room.ownerName ?? 'Admin';
    return '$owner Sohbet sesli odasına katıldı! 🎤';
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final live = ref.watch(voiceRoomLiveProvider(room));
    final coins = ref.watch(coinBalanceProvider).valueOrNull ??
        ref.watch(authControllerProvider).valueOrNull?.coinBalance ??
        0;
    final online = live.presence.isNotEmpty
        ? live.presence.length
        : room.displayOnline;
    final user = ref.watch(authControllerProvider).valueOrNull;
    final speakingId = _micOn ? user?.id : null;
    final perms = _permissions(room, live.presence);
    final isOwner = perms.isRoomOwner;
    final showMusic = VoiceMusicAccess.canShowMusicCard(
      dj: live.dj,
      perms: perms,
      jetonBalance: coins,
    );

    ref.listen(voiceRoomUiProvider, (prev, next) {
      if (prev?.backgroundMusicEnabled != next.backgroundMusicEnabled) {
        unawaited(
          ref.read(voiceRoomLiveProvider(room).notifier).refresh(includeDj: true),
        );
      }
    });

    ref.listen(pkBattleRemoteProvider, (prev, next) {
      if (next == null || !isOwner || !next.isPending) return;
      final opp = next.opponentVoiceRoomId;
      final isTarget = opp == room.apiRoomKey ||
          opp == room.id ||
          opp == room.slug;
      if (!isTarget || _shownPkInviteId == next.id) return;
      _shownPkInviteId = next.id;
      _showIncomingPkInvite(next.id);
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: Scaffold(
        backgroundColor: AppDesign.bgBase,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _RoomBackground(url: room.backgroundImageUrl),
            if (_joining)
              const Center(child: DiscoverAccentLoader())
            else if (!_joined)
              Center(
                child: DiscoverEmptyState(
                  icon: Icons.headset_off_rounded,
                  message: _error ?? 'Bağlantı kurulamadı',
                  actionLabel: 'Tekrar dene',
                  action: () {
                    setState(() {
                      _joining = true;
                      _error = null;
                    });
                    _joinRoom();
                  },
                ),
              )
            else
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                      child: VoiceRoomTopBar(
                        room: room,
                        onlineCount: online,
                        onBack: _leave,
                        onExit: _leave,
                        onShare: _shareRoom,
                        isCurrentUserOwner: isOwner,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: VoiceRoomSeatsPanel(
                        room: room,
                        presence: live.presence,
                        speakingUserId: speakingId,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          children: [
                            if (_announcementVisible)
                              VoiceRoomAnnouncement(
                                text: room.descTr?.trim().isNotEmpty == true
                                    ? room.descTr!.trim()
                                    : 'Sohbet odasına hoş geldiniz...',
                                onDismiss: () =>
                                    setState(() => _announcementVisible = false),
                              ),
                            if (_announcementVisible) const SizedBox(height: 6),
                            VoiceRoomSystemBanner(
                              message: _latestSystemJoin(live.messages),
                            ),
                            const SizedBox(height: 8),
                            VoiceRoomMusicMiniPlayer(
                              dj: live.dj,
                              canModerate: perms.canModerate || isOwner,
                              onTap: showMusic
                                  ? () => showVoiceMusicHubPage(
                                        context,
                                        ref,
                                        room: room,
                                        perms: perms,
                                        isOwner: isOwner,
                                      )
                                  : null,
                              onSkip: (perms.canModerate || isOwner)
                                  ? () => ref
                                      .read(voiceRoomLiveProvider(room).notifier)
                                      .skipMusic()
                                  : null,
                              onStop: () => ref
                                  .read(voiceRoomLiveProvider(room).notifier)
                                  .stopRoomMusic(
                                    clearQueue: perms.canModerate || isOwner,
                                  ),
                            ),
                            VoiceRoomActionRow(
                              dj: live.dj,
                              onMusicTap: showMusic
                                  ? () => showVoiceMusicHubPage(
                                        context,
                                        ref,
                                        room: room,
                                        perms: perms,
                                        isOwner: isOwner,
                                      )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: VoiceRoomChatPanel(
                                messages: live.messages,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    VoiceRoomBottomBar(
                      controller: _messageCtrl,
                      coinBalance: coins,
                      micOn: _micOn,
                      sending: live.sending,
                      onMicToggle: () {
                        final next = !_micOn;
                        _trtc.setMicEnabled(next);
                        setState(() => _micOn = next);
                      },
                      onSend: () {
                        final text = _messageCtrl.text;
                        _messageCtrl.clear();
                        ref
                            .read(voiceRoomLiveProvider(room).notifier)
                            .sendMessage(text);
                      },
                      onRefresh: () => ref
                          .read(voiceRoomLiveProvider(room).notifier)
                          .refresh(),
                      onShare: _shareRoom,
                      onTopUp: () {
                        context.push(
                          CanlifalWebRoute.location(
                            relativePath: '/cuzdan',
                            title: 'Jeton Yükle',
                          ),
                        );
                      },
                      onGiftTap: () {
                        context.push(
                          CanlifalWebRoute.location(
                            relativePath: '/sohbet/${room.slug}',
                            title: 'Hediye Gönder',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            if (_joined && isOwner)
              Positioned(
                right: 16,
                bottom: 100,
                child: FloatingActionButton.extended(
                  heroTag: 'voice-pk-fab',
                  backgroundColor: const Color(0xFFB832FF),
                  onPressed: () {
                    final active = ref.read(pkBattleRemoteProvider);
                    if (active?.isActive == true) {
                      _openActivePk();
                    } else {
                      showVoiceMoreMenuSheet(
                        context,
                        ref: ref,
                        room: room,
                        live: live,
                        perms: perms,
                        onSettings: () {},
                        onSpeakers: () {},
                        onShare: _shareRoom,
                        onBackgroundMusic: () {},
                        onPkBattle: _openPkInvite,
                      );
                    }
                  },
                  icon: const Icon(Icons.flash_on_rounded),
                  label: Text(
                    ref.watch(pkBattleRemoteProvider)?.isActive == true
                        ? 'PK'
                        : 'PK Başlat',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoomBackground extends StatelessWidget {
  const _RoomBackground({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppDesign.bgPurpleGlow, AppDesign.bgBase],
            ),
          ),
        ),
        if (url != null && url!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.55),
            colorBlendMode: BlendMode.darken,
          ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    AppDesign.bgBase.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
