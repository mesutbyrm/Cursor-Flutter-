import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/widgets/cached_cover_image.dart';
import '../../../core/navigation/wallet_navigation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../live/domain/entities/live_gift_event.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/presentation/providers/live_providers.dart';
import '../domain/entities/chat_room_message.dart';
import '../domain/voice_official_join.dart';
import '../../gifts/domain/premium_gift_catalog_2026.dart';
import '../../gifts/presentation/widgets/premium_2026/premium_gift_fullscreen_overlay.dart';
import 'providers/voice_gift_combo_tracker.dart';
import 'providers/voice_gift_leaderboard_provider.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../domain/entities/chat_room_presence.dart';
import '../../trtc/presentation/providers/trtc_providers.dart';
import 'audio/voice_room_audio_coordinator.dart';
import 'providers/chat_room_providers.dart';
import 'providers/pk_battle_remote_provider.dart';
import 'utils/voice_room_image_prefetch.dart';
import 'providers/voice_gift_providers.dart';
import 'providers/voice_room_audio_providers.dart';
import 'providers/voice_room_ui_provider.dart';
import '../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../vip_gold/presentation/widgets/vip_entrance_overlay.dart';
import 'sheets/voice_room_hub_settings.dart';
import 'sheets/voice_room_sheets.dart';
import 'pages/voice_music_hub_page.dart';
import 'utils/voice_music_access.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import 'theme/voice_room_tokens.dart';
import 'utils/voice_room_permissions.dart';
import 'widgets/premium/voice_gift_flight_overlay.dart';
import 'widgets/premium/voice_glass.dart';
import 'widgets/premium_2026/voice_cosmic_background.dart';
import 'widgets/premium_2026/voice_room_audience_strip.dart';
import 'sheets/voice_room_commands_panel.dart';
import 'sheets/voice_room_dj_sheet.dart';
import 'widgets/premium_2026/voice_room_persistent_duyuru.dart';
import 'widgets/premium_2026/voice_web_bottom_nav.dart';
import 'widgets/premium_2026/voice_web_chat_overlay.dart';
import 'widgets/premium_2026/voice_web_owner_stage.dart';
import 'widgets/premium_2026/voice_web_room_header.dart';
import 'widgets/voice_room/voice_room_action_row.dart';
import 'widgets/voice_room/voice_room_music_mini_player.dart';
import 'widgets/voice_room/voice_staff_entrance_marquee.dart';
import 'widgets/voice_room/voice_room_music_request_flash.dart';

/// Premium sesli sohbet — LiveKit (öncelik) / TRTC + uçan hediyeler.
class VoiceRoomRtcPage extends ConsumerStatefulWidget {
  const VoiceRoomRtcPage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<VoiceRoomRtcPage> createState() => _VoiceRoomRtcPageState();
}

class _VoiceRoomRtcPageState extends ConsumerState<VoiceRoomRtcPage> {
  VoiceRoomAudioCoordinator? _audio;
  StreamSubscription<LiveGiftEvent>? _giftSub;
  final _messageCtrl = TextEditingController();
  var _audioJoining = true;
  var _audioReady = false;
  String? _audioError;
  String? _loginError;
  var _micOn = true;
  var _leaving = false;
  LiveGiftEvent? _fullscreenGift;
  var _showVipEntrance = false;
  var _vipEntrancePlayed = false;
  String? _shownPkInviteId;
  final _messageFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(voiceRoomsProvider);
      _joinRoom();
      _prefetchRoomImages();
    });
  }

  VoiceRoomEntity _roomSynced(List<VoiceRoomEntity>? rooms) {
    final w = widget.room;
    if (rooms == null) return w;
    for (final r in rooms) {
      if (r.id == w.id ||
          r.slug == w.slug ||
          r.apiRoomKey == w.apiRoomKey ||
          (w.slug.isNotEmpty && r.slug == w.slug)) {
        return r;
      }
    }
    return w;
  }

  @override
  void dispose() {
    _giftSub?.cancel();
    _messageCtrl.dispose();
    _messageFocus.dispose();
    _audio?.dispose();
    super.dispose();
  }

  Future<void> _prefetchRoomImages() async {
    if (!mounted) return;
    final room = widget.room;
    final bg = ref.read(voiceRoomLiveProvider(room)).backgroundUrl ??
        room.backgroundImageUrl;
    if (bg == null || bg.isEmpty) return;
    await prefetchVoiceRoomImages(context, primaryUrl: bg);
  }

  void _sendChatMessage(VoiceRoomEntity room) {
    final text = VoiceOfficialJoin.normalizeCommandInput(
      _messageCtrl.text.trim(),
    );
    if (text.isEmpty) return;
    _messageCtrl.clear();
    unawaited(() async {
      await ref.read(voiceRoomLiveProvider(room).notifier).sendMessage(text);
      if (!mounted) return;
      final err = ref.read(voiceRoomLiveProvider(room)).error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }());
  }

  void _startGiftRealtime() {
    final service = ref.read(voiceRoomGiftRealtimeProvider);
    final room = widget.room;
    service.start(room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id);
    _giftSub?.cancel();
    _giftSub = service.events.listen(_onGiftEvent);
  }

  void _onGiftEvent(LiveGiftEvent raw) {
    if (!mounted) return;
    final ui = ref.read(voiceRoomUiProvider);
    if (!ui.giftAnimationsEnabled) return;

    final event = ref.read(voiceGiftComboTrackerProvider.notifier).enrich(raw);
    ref.read(voiceSessionGiftLeaderboardProvider.notifier).record(event);
    ref.read(voiceGiftFlightQueueProvider.notifier).enqueue(event);

    final showFullscreen = PremiumGiftCatalog2026.triggersFullscreen(
      giftId: event.giftId,
      coinCost: event.coinCost,
      combo: event.combo,
    );
    if (showFullscreen) {
      final rarity = PremiumGiftCatalog2026.rarity(event.giftId);
      final duration = rarity.fullscreenDuration;
      setState(() => _fullscreenGift = event);
      Future.delayed(duration, () {
        if (mounted && _fullscreenGift?.id == event.id) {
          setState(() => _fullscreenGift = null);
        }
      });
    }
  }

  Future<void> _joinRoom() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      setState(() {
        _audioJoining = false;
        _loginError = 'Odaya girmek için giriş yapın';
      });
      return;
    }

    setState(() {
      _audioJoining = true;
      _audioError = null;
      _loginError = null;
    });

    _audio = ref.read(voiceRoomAudioCoordinatorProvider);
    if (!_audio!.isSupported) {
      setState(() {
        _audioJoining = false;
        _audioError = 'Ses bağlantısı bu cihazda desteklenmiyor; sohbet çalışır';
      });
      _startGiftRealtime();
      _maybeShowVipEntrance(user);
      unawaited(_connectPkBattle());
      return;
    }

    try {
      final perms = VoiceRoomPermissions.forUser(user: user, room: widget.room);
      await _audio!.join(
        trtcRoomId: widget.room.trtcRoomId,
        userId: user.id,
        isHost: _isRoomOwner(user.id, user.username) || perms.isSiteAdmin,
        liveKitRemote: ref.read(liveKitRemoteProvider),
        trtcRemote: ref.read(trtcRemoteProvider),
      );
      if (perms.isSiteAdmin) {
        _audio?.setMicEnabled(true);
      }
      if (mounted) {
        setState(() {
          _audioJoining = false;
          _audioReady = true;
          _micOn = _audio!.micOn;
        });
        _startGiftRealtime();
        _audio?.setHeadphonesOn(ref.read(voiceRoomUiProvider).headphonesOn);
        _maybeShowVipEntrance(user);
        unawaited(_connectPkBattle());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _audioJoining = false;
          _audioError = ApiException.userMessage(e);
        });
        _startGiftRealtime();
        _maybeShowVipEntrance(user);
        unawaited(_connectPkBattle());
      }
    }
  }

  Future<void> _connectPkBattle() async {
    if (!mounted) return;
    final r = widget.room;
    final roomKey = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
    final remote = ref.read(pkBattleRemoteProvider.notifier);
    await remote.loadRoomBattle(roomKey);
    if (!mounted) return;
    remote.connectSocket(
      roomId: roomKey,
      alternateRoomId: r.slug != roomKey ? r.slug : null,
      battleId: ref.read(pkBattleRemoteProvider)?.id,
    );
  }

  void _maybeShowVipEntrance(UserEntity user) {
    if (_vipEntrancePlayed || !mounted) return;
    final tier = ref.read(vipTierProvider);
    if (!tier.hasEntranceFx) return;
    _vipEntrancePlayed = true;
    setState(() => _showVipEntrance = true);
  }

  Future<void> _leaveRoom() async {
    if (_leaving) return;
    _leaving = true;
    ref.read(pkBattleRemoteProvider.notifier).clear();
    ref.read(voiceRoomGiftRealtimeProvider).stop();
    await _audio?.leave();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/voice-rooms');
    }
    _leaving = false;
  }

  Future<void> _leave() async {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F2E),
        title: const Text('Odadan çık', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Sesli sohbet listesine dönmek ister misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ana liste'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) await _leaveRoom();
  }

  VoiceRoomPermissions _perms(
    UserEntity? user,
    List<ChatRoomPresence> presence,
  ) {
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
      room: widget.room,
      selfPresence: self,
    );
  }

  bool _isRoomOwner(String userId, String username) {
    final room = widget.room;
    final oid = room.ownerId;
    if (oid != null && oid.isNotEmpty && oid == userId) return true;
    final uname = username.trim().toLowerCase();
    final slug = room.slug.trim().toLowerCase();
    return uname.isNotEmpty && slug == uname;
  }

  void _shareRoom() {
    final slug = widget.room.slug;
    final url = '${Env.siteOrigin}/sohbet/$slug';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Paylaşım linki kopyalandı: $url')),
    );
  }

  void _openPkInvite(VoiceRoomEntity room) {
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    context.push('/voice-room/$key/pk-invite', extra: room);
  }

  void _openActivePk(VoiceRoomEntity room) {
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    context.push('/voice-room/$key/pk', extra: room);
  }

  Future<void> _showIncomingPkInvite(String battleId) async {
    if (!mounted) return;
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F2E),
        title: const Text('PK Daveti', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bir oda size PK daveti gönderdi. Kabul ediyor musunuz?',
          style: TextStyle(color: Colors.white70),
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
    if (accept == true) {
      await remote.accept(battleId);
      if (mounted) _openActivePk(widget.room);
    } else if (accept == false) {
      await remote.reject(battleId);
    }
  }

  Future<void> _pickBackground(BuildContext context, VoiceRoomEntity room) async {
    final urls =
        await ref.read(voiceRoomLiveProvider(room).notifier).fetchBackgrounds();
    if (!context.mounted || urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arka plan listesi alınamadı')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (_, scroll) => VoiceGlass(
          borderRadius: 24,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Oda arka planı',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'canlifal.com görselleri',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  controller: scroll,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: urls.length,
                  itemBuilder: (_, i) {
                    final url = urls[i];
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final err = await ref
                            .read(voiceRoomLiveProvider(room).notifier)
                            .setRoomBackground(url);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(err ?? 'Arka plan güncellendi'),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedCoverImage(url: url, fit: BoxFit.cover),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                color: Colors.black54,
                                child: Text(
                                  url.split('/').last,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openUser(ChatRoomPresence user) {
    showVoiceUserProfileSheet(
      context,
      user: user,
      isOwner: _isRoomOwner(
        ref.read(authControllerProvider).valueOrNull?.id ?? '',
        ref.read(authControllerProvider).valueOrNull?.username ?? '',
      ),
    );
  }

  void _openHubSettings(
    BuildContext context, {
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
    required VoiceRoomPermissions perms,
    required bool isOwner,
  }) {
    showVoiceRoomHubSettingsSheet(
      context,
      ref,
      room: room,
      live: live,
      perms: perms,
      isOwner: isOwner,
      onUserTap: _openUser,
    );
  }

  Future<void> _onSeatTap(
    BuildContext context, {
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
    required VoiceRoomPermissions perms,
    required int internalSeatIndex,
    ChatRoomPresence? occupant,
  }) async {
    if (occupant != null) {
      _openUser(occupant);
      return;
    }
    if (perms.canAssignSeats) {
      await _showAssignSeatSheet(
        context,
        room: room,
        live: live,
        seatIndex: internalSeatIndex,
      );
      return;
    }
    if (perms.canTakeSeat) {
      final err = await ref
          .read(voiceRoomLiveProvider(room).notifier)
          .assignSeat(seatIndex: internalSeatIndex);
      if (!context.mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }
    await _requestSpeakFromSeat(
      context,
      room,
      ref.read(voiceRoomUiProvider),
    );
  }

  Future<void> _showAssignSeatSheet(
    BuildContext context, {
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
    required int seatIndex,
  }) async {
    final self = ref.read(authControllerProvider).valueOrNull;
    final onStage = voiceWebOnStageIds(room: room, presence: live.presence);
    final candidates = live.presence
        .where((p) => !onStage.contains(p.id) || p.seatIndex == seatIndex)
        .toList();

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
              'Koltuk $seatIndex',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (self != null)
              ListTile(
                leading: const Icon(Icons.event_seat_rounded),
                title: const Text('Bu koltuğa otur'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final err = await ref
                      .read(voiceRoomLiveProvider(room).notifier)
                      .assignSeat(seatIndex: seatIndex);
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
                      ? NetworkImage(p.image!)
                      : null,
                  child: p.image == null || p.image!.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(p.displayName),
                onTap: () async {
                  Navigator.pop(ctx);
                  final err = await ref
                      .read(voiceRoomLiveProvider(room).notifier)
                      .assignSeat(
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

  Future<void> _requestSpeakFromSeat(
    BuildContext context,
    VoiceRoomEntity room,
    VoiceRoomUiState ui,
  ) async {
    final liveCtrl = ref.read(voiceRoomLiveProvider(room).notifier);
    final err = ui.requestSpeakPending
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
        final ctrl = ref.read(voiceRoomLiveProvider(room).notifier);
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

  @override
  Widget build(BuildContext context) {
    final room = _roomSynced(ref.watch(voiceRoomsProvider).valueOrNull);
    final live = ref.watch(voiceRoomLiveProvider(room));
    final ui = ref.watch(voiceRoomUiProvider);
    final flightQueue = ref.watch(voiceGiftFlightQueueProvider);
    final online = live.onlineCountFor(room);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final perms = _perms(user, live.presence);
    final isOwner = perms.isRoomOwner || perms.isSiteAdmin;
    final jeton = VoiceMusicAccess.jetonFromBalances(
      ref.watch(walletBalancesProvider).valueOrNull,
    );
    final showMusicCard = VoiceMusicAccess.canShowMusicCard(
      dj: live.dj,
      perms: perms,
      jetonBalance: jeton,
    );
    final speakingIds = <String>{
      for (final p in live.presence)
        if (p.isSpeaking) p.id,
    };
    if (_micOn && user != null) speakingIds.add(user.id);
    final speakingId = (_micOn && user != null)
        ? user.id
        : (speakingIds.isNotEmpty ? speakingIds.first : null);
    final bgUrl = live.backgroundUrl ?? room.backgroundImageUrl;
    final staffBanner = live.enterBanner;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardOpen = viewInsets.bottom > 0;
    final mq = MediaQuery.sizeOf(context);
    final audience = voiceWebAudienceOffStage(presence: live.presence, room: room);
    final chatMaxH = keyboardOpen
        ? (mq.height * 0.22).clamp(96.0, 160.0)
        : (mq.height * 0.28).clamp(120.0, 220.0);
    final duyuru = ((room.descTr ?? room.rulesTr)?.trim().isNotEmpty == true)
        ? (room.descTr ?? room.rulesTr)!.trim()
        : 'Sohbet odasına hoş geldiniz. Saygılı olun, keyifli sohbetler!';
    ChatRoomPresence? ownerPresence;
    if (room.ownerId != null) {
      for (final p in live.presence) {
        if (p.id == room.ownerId) {
          ownerPresence = p;
          break;
        }
      }
    }
    final ownerName = ownerPresence?.displayName ?? room.ownerName;
    final ownerAvatar = ownerPresence?.image ?? room.ownerAvatarUrl;
    final headerAvatar = ownerAvatar ?? room.ownerAvatarUrl;
    ref.listen<VoiceRoomLiveState>(voiceRoomLiveProvider(room), (prev, next) {
      if (prev?.error != next.error && next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
      if (next.openCommandsPanel && !(prev?.openCommandsPanel ?? false)) {
        ref.read(voiceRoomLiveProvider(room).notifier).clearOpenCommandsPanel();
        if (!mounted) return;
        unawaited(
          showVoiceRoomCommandsPanel(
            context,
            ref,
            room: room,
            perms: perms,
            isOwner: isOwner,
          ),
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
      unawaited(_showIncomingPkInvite(next.id));
    });

    ref.listen(voiceRoomUiProvider, (prev, next) {
      if (prev?.backgroundMusicEnabled != next.backgroundMusicEnabled) {
        unawaited(
          ref.read(voiceRoomLiveProvider(room).notifier).refresh(includeDj: true),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final rootNav = Navigator.of(context);
        if (rootNav.canPop()) {
          rootNav.pop();
          return;
        }
        await _leave();
      },
      child: Scaffold(
        backgroundColor: VoiceRoomTokens.bgDeep,
        resizeToAvoidBottomInset: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            VoiceCosmicBackground(imageUrl: bgUrl),
            if (_loginError != null)
              Center(
                child: DiscoverEmptyState(
                  icon: Icons.login_rounded,
                  message: _loginError!,
                  actionLabel: 'Giriş',
                  action: () => context.push('/login'),
                ),
              )
            else
              Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_audioJoining)
                          const LinearProgressIndicator(
                            minHeight: 2,
                            color: VoiceRoomTokens.neonPurple,
                          ),
                        if (_audioError != null)
                          Material(
                            color: AppThemeColors.liveRed.withValues(alpha: 0.15),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.headset_off_rounded,
                                color: AppThemeColors.liveRed,
                                size: 20,
                              ),
                              title: Text(
                                _audioReady
                                    ? 'Ses: $_audioError'
                                    : 'Ses bağlanamadı — sohbet aktif',
                                style: const TextStyle(fontSize: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: TextButton(
                                onPressed: _joinRoom,
                                child: const Text('Tekrar'),
                              ),
                            ),
                          ),
                        VoiceWebRoomHeader(
                          room: room,
                          onlineCount: online,
                          roomAvatarUrl: headerAvatar,
                          onBack: _leave,
                          onExit: _leave,
                          onAudience: () => showVoiceSpeakerListSheet(
                            context,
                            presence: live.presence,
                            room: room,
                            onUserTap: _openUser,
                          ),
                          onGallery: perms.canChangeBackground
                              ? () => _pickBackground(context, room)
                              : null,
                          onSettings: () => _openHubSettings(
                            context,
                            room: room,
                            live: live,
                            perms: perms,
                            isOwner: isOwner,
                          ),
                        ),
                        if (live.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              live.error!,
                              style: const TextStyle(
                                color: AppThemeColors.liveRed,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (!keyboardOpen)
                          VoiceStaffEntranceMarquee(
                            message: staffBanner,
                            roomName: room.nameTr,
                          ),
                        VoiceWebOwnerStage(
                          room: room,
                          presence: live.presence,
                          speakingUserId: speakingId,
                          onUserTap: _openUser,
                          onSeatTap: (seatIndex, user) => unawaited(
                            _onSeatTap(
                              context,
                              room: room,
                              live: live,
                              perms: perms,
                              internalSeatIndex: seatIndex,
                              occupant: user,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        VoiceWebRoomInfoPill(
                          room: room,
                          ownerName: ownerName,
                          ownerAvatarUrl: ownerAvatar,
                        ),
                        if (!keyboardOpen) ...[
                          VoiceRoomPersistentDuyuru(
                            text: duyuru,
                            canEdit: perms.canModerate || isOwner,
                          ),
                          VoiceRoomMusicMiniPlayer(
                            dj: live.dj,
                            canModerate: perms.canModerate || isOwner,
                            onTap: showMusicCard
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
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: VoiceRoomActionRow(
                              dj: live.dj,
                              showMusicCard: showMusicCard,
                              onMusicTap: () => showVoiceMusicHubPage(
                                context,
                                ref,
                                room: room,
                                perms: perms,
                                isOwner: isOwner,
                              ),
                              onDjTap: () => showVoiceRoomDjSheet(
                                context,
                                ref,
                                room: room,
                                live: live,
                                perms: perms,
                                isOwner: isOwner,
                              ),
                            ),
                          ),
                          VoiceRoomMusicRequestFlash(
                            message: live.musicRequestFlash,
                          ),
                          const SizedBox(height: 2),
                          VoiceRoomAudienceStrip(
                            audience: audience,
                            totalOnline: online,
                            onUserTap: _openUser,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: VoiceWebChatOverlay(
                        messages: live.messages,
                        hideOfficialJoinInChat: staffBanner != null,
                        maxHeight: chatMaxH,
                        onUserTap: (id, _) {
                          for (final e in live.presence) {
                            if (e.id == id) {
                              _openUser(e);
                              break;
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            VoiceGiftFlightOverlay(
              events: flightQueue,
              enabled: ui.giftAnimationsEnabled,
              onFinished: (id) =>
                  ref.read(voiceGiftFlightQueueProvider.notifier).dequeue(id),
            ),
            PremiumGiftFullscreenOverlay(event: _fullscreenGift),
            if (_loginError == null && isOwner && !keyboardOpen)
              Positioned(
                right: 10,
                bottom: MediaQuery.paddingOf(context).bottom + 188,
                child: Material(
                  color: const Color(0xFFB832FF),
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  child: InkWell(
                    onTap: () {
                      final active = ref.read(pkBattleRemoteProvider);
                      if (active?.isActive == true) {
                        _openActivePk(room);
                      } else {
                        _openPkInvite(room);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flash_on_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ref.watch(pkBattleRemoteProvider)?.isActive == true
                                ? 'PK'
                                : 'PK',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_loginError == null && !keyboardOpen)
              Positioned(
                right: 4,
                bottom: MediaQuery.paddingOf(context).bottom + 112,
                child: VoiceWebFloatingRail(
                  onTools: () => showVoiceRoomCommandsPanel(
                    context,
                    ref,
                    room: room,
                    perms: perms,
                    isOwner: isOwner,
                  ),
                  onMusic: showMusicCard
                      ? () => showVoiceMusicHubPage(
                            context,
                            ref,
                            room: room,
                            perms: perms,
                            isOwner: isOwner,
                          )
                      : null,
                ),
              ),
            if (_showVipEntrance && user != null)
              VipEntranceOverlay(
                tier: ref.watch(vipTierProvider),
                userName: user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!.trim()
                    : user.username,
                onFinished: () {
                  if (mounted) setState(() => _showVipEntrance = false);
                },
              ),
          ],
        ),
        bottomNavigationBar: _loginError != null
            ? null
            : AnimatedPadding(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VoiceWebChatInputBar(
                        controller: _messageCtrl,
                        focusNode: _messageFocus,
                        sending: false,
                        onSend: () => _sendChatMessage(room),
                      ),
                    if (!keyboardOpen)
                      VoiceWebBottomNav(
                        micOn: _micOn,
                        micEnabled: _audioReady,
                        headphonesOn: ui.headphonesOn,
                        onHome: _leave,
                        onSpeaker: () {
                          ref.read(voiceRoomUiProvider.notifier).toggleHeadphones();
                          _audio?.setHeadphonesOn(
                            ref.read(voiceRoomUiProvider).headphonesOn,
                          );
                        },
                        onMic: () {
                          if (!_audioReady) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Mikrofon için ses bağlantısı gerekli',
                                ),
                              ),
                            );
                            return;
                          }
                          final next = !_micOn;
                          _audio?.setMicEnabled(next);
                          setState(() => _micOn = next);
                        },
                        onCoins: () => openJetonStore(context, ref: ref),
                        onSettings: () => _openHubSettings(
                          context,
                          room: room,
                          live: live,
                          perms: perms,
                          isOwner: isOwner,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
