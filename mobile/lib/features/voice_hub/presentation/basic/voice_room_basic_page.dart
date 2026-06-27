import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/performance/voice_room_entry_perf.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/voice_official_join.dart';
import '../../../gifts/domain/premium_gift_catalog_2026.dart';
import '../../../gifts/presentation/widgets/premium_2026/premium_gift_fullscreen_overlay.dart';
import '../providers/voice_gift_combo_tracker.dart';
import '../providers/voice_gift_leaderboard_provider.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_gift_providers.dart';
import '../audio/voice_room_audio_coordinator.dart';
import '../audio/voice_room_music_audio_session.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_audio_providers.dart';
import '../providers/voice_room_ui_provider.dart';
import '../../domain/entities/voice_room_realtime_event.dart';
import '../../domain/voice_music_sync.dart';
import '../utils/voice_room_permissions.dart';
import '../theme/voice_room_tokens.dart';
import '../widgets/premium/voice_gift_flight_overlay.dart';
import '../widgets/premium_2026/voice_cosmic_background.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../../vip_gold/presentation/widgets/vip_entrance_overlay.dart';
import 'voice_room_basic_moderation_section.dart';
import 'voice_room_basic_premium_section.dart';
import '../../music/presentation/widgets/music_search_picker_sheet.dart';
import '../utils/kick_strike_ui.dart';
import '../widgets/voice_room_error_boundary.dart';

/// Aşama 1 — oda listesi, giriş/çıkış, mikrofon, hoparlör, katılımcılar, oda sahibi.
class VoiceRoomBasicPage extends ConsumerStatefulWidget {
  const VoiceRoomBasicPage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<VoiceRoomBasicPage> createState() => _VoiceRoomBasicPageState();
}

class _VoiceRoomBasicPageState extends ConsumerState<VoiceRoomBasicPage> {
  VoiceRoomAudioCoordinator? _audio;
  String? _pinnedLiveRoomKey;
  var _audioJoining = false;
  var _audioReady = false;
  String? _audioError;
  String? _loginError;
  var _isMicMuted = true;
  var _leaving = false;
  final _istekCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  StreamSubscription<LiveGiftEvent>? _giftSub;
  LiveGiftEvent? _fullscreenGift;
  var _showVipEntrance = false;
  var _vipEntrancePlayed = false;
  String? _shownPkInviteId;

  String get _liveRoomKey {
    final pinned = _pinnedLiveRoomKey?.trim();
    if (pinned != null && pinned.isNotEmpty) return pinned;
    final key = _effectiveRoom().apiRoomKey;
    if (key.isNotEmpty) _pinnedLiveRoomKey = key;
    return key.isNotEmpty ? key : widget.room.apiRoomKey;
  }

  VoiceRoomEntity _effectiveRoom() {
    final w = widget.room;
    final rooms = ref.read(voiceRoomsProvider).valueOrNull;
    if (rooms == null) return w;
    for (final r in rooms) {
      if (r.id == w.id || r.apiRoomKey == w.apiRoomKey) return r;
    }
    return w;
  }

  @override
  void initState() {
    super.initState();
    if (widget.room.apiRoomKey.isNotEmpty) {
      _pinnedLiveRoomKey = widget.room.liveKey;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.room.apiRoomKey.isEmpty) {
        unawaited(ref.read(voiceRoomsProvider.future));
      }
      _startPremiumRealtime(ref.read(authControllerProvider).valueOrNull);
      unawaited(_joinAudioBackground());
    });
  }

  @override
  void dispose() {
    _istekCtrl.dispose();
    _messageCtrl.dispose();
    _giftSub?.cancel();
    ref.read(voiceRoomGiftRealtimeProvider).stop();
    final audio = _audio;
    _audio = null;
    if (audio != null) {
      unawaited(
        audio.leave().whenComplete(() {
          try {
            audio.dispose();
          } catch (_) {}
        }),
      );
    }
    super.dispose();
  }

  Future<UserEntity?> _waitForAuth() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoading) return auth.valueOrNull;
    try {
      return await ref.read(authControllerProvider.future).timeout(
            VoiceRoomEntryPerf.entryBudget,
          );
    } catch (_) {
      return ref.read(authControllerProvider).valueOrNull;
    }
  }

  bool _isRoomOwner(UserEntity user, VoiceRoomEntity room) {
    final oid = room.ownerId;
    if (oid != null && oid.isNotEmpty && oid == user.id) return true;
    final uname = user.username.trim().toLowerCase();
    final slug = room.slug.trim().toLowerCase();
    return uname.isNotEmpty && slug == uname;
  }

  void _startPremiumRealtime(UserEntity? user) {
    if (user == null) return;
    _startGiftRealtime();
    _maybeShowVipEntrance(user);
    unawaited(connectVoiceRoomBasicPkBattle(ref, _effectiveRoom()));
  }

  Future<void> _joinAudioBackground() async {
    if (!mounted) return;
    setState(() {
      _audioJoining = true;
      _audioError = null;
    });

    final user = await _waitForAuth();
    if (!mounted) return;
    if (user == null) {
      setState(() {
        _audioJoining = false;
        _loginError = 'Odaya girmek için giriş yapın';
      });
      return;
    }

    var room = _effectiveRoom();
    if (room.apiRoomKey.isEmpty && widget.room.apiRoomKey.isNotEmpty) {
      room = widget.room;
      _pinnedLiveRoomKey = room.liveKey;
    }
    if (room.apiRoomKey.isEmpty) {
      setState(() {
        _audioJoining = false;
        _audioError = 'Oda bilgisi yüklenemedi';
      });
      return;
    }

    _audio = ref.read(voiceRoomAudioCoordinatorProvider);
    if (!_audio!.isSupported) {
      setState(() {
        _audioJoining = false;
        _audioError = 'Ses bu cihazda desteklenmiyor';
      });
      _startPremiumRealtime(user);
      return;
    }

    try {
      final live = ref.read(voiceRoomLiveProvider(_liveRoomKey));
      final perms = VoiceRoomPermissions.forUser(
        user: user,
        room: room,
        server: live.serverPermissions,
      );
      await _audio!.join(
        trtcRoomId: room.trtcRoomId,
        userId: user.id,
        isHost: _isRoomOwner(user, room) || perms.isSiteAdmin,
        liveKitRemote: ref.read(liveKitRemoteProvider),
        trtcRemote: ref.read(trtcRemoteProvider),
        prefetchedTrtc: VoiceRoomEntryPerf.takeTrtc(
          userId: user.id,
          roomId: room.trtcRoomId,
        ),
      );
      if (!mounted) return;
      unawaited(VoiceRoomMusicAudioSession.activateForPlayback());
      _audio!.setHeadphonesOn(ref.read(voiceRoomUiProvider).headphonesOn);
      setState(() {
        _audioJoining = false;
        _audioReady = true;
        _isMicMuted = !_audio!.micOn;
      });
      _startPremiumRealtime(user);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _audioJoining = false;
        _audioError = ApiException.userMessage(e);
      });
      _startPremiumRealtime(user);
    }
  }

  void _toggleMic() {
    if (_audio == null || !_audioReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses bağlantısı hazır değil')),
      );
      return;
    }
    final muted = !_isMicMuted;
    _audio!.setMicEnabled(!muted);
    setState(() => _isMicMuted = muted);
  }

  void _toggleSpeaker() {
    ref.read(voiceRoomUiProvider.notifier).toggleHeadphones();
    _audio?.setHeadphonesOn(ref.read(voiceRoomUiProvider).headphonesOn);
    setState(() {});
  }

  void _startGiftRealtime() {
    final room = _effectiveRoom();
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (key.isEmpty) return;
    final service = ref.read(voiceRoomGiftRealtimeProvider);
    service.start(key);
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
      setState(() => _fullscreenGift = event);
      final duration = PremiumGiftCatalog2026.rarity(event.giftId).fullscreenDuration;
      Future.delayed(duration, () {
        if (mounted && _fullscreenGift?.id == event.id) {
          setState(() => _fullscreenGift = null);
        }
      });
    }
  }

  void _maybeShowVipEntrance(UserEntity user) {
    if (_vipEntrancePlayed || !mounted) return;
    final tier = ref.read(vipTierProvider);
    if (!tier.hasEntranceFx) return;
    _vipEntrancePlayed = true;
    setState(() => _showVipEntrance = true);
  }

  void _openGiftShop(
    VoiceRoomEntity room,
    List<ChatRoomPresence> presence, {
    ChatRoomPresence? receiver,
  }) {
    openVoiceRoomBasicGiftShop(
      context,
      ref,
      room: room,
      presence: presence,
      receiver: receiver,
    );
  }

  void _sendChatMessage() {
    final text = VoiceOfficialJoin.normalizeCommandInput(
      _messageCtrl.text.trim(),
    );
    if (text.isEmpty) return;
    _messageCtrl.clear();
    unawaited(
      ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).sendMessage(text),
    );
  }

  Future<void> _leaveRoom() async {
    if (_leaving) return;
    _leaving = true;

    ref.read(pkBattleRemoteProvider.notifier).clear();
    ref.read(voiceRoomGiftRealtimeProvider).stop();
    _giftSub?.cancel();
    _giftSub = null;

    final liveCtrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
    final audio = _audio;
    _audio = null;

    unawaited(liveCtrl.leaveRoomSession(source: 'basic_leave'));
    if (audio != null) {
      unawaited(
        audio.leave().whenComplete(() {
          try {
            audio.dispose();
          } catch (_) {}
        }),
      );
    }

    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/voice-rooms');
    }
    _leaving = false;
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odadan çık'),
        content: const Text('Sesli sohbetten ayrılmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çık'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) await _leaveRoom();
  }

  void _openTools(
    VoiceRoomEntity room,
    VoiceRoomLiveState live,
    VoiceRoomPermissions perms,
    bool isOwner,
    UserEntity? user,
    bool canControlMusic,
  ) {
    showVoiceRoomBasicToolsSheet(
      context,
      ref,
      room: room,
      liveKey: _liveRoomKey,
      live: live,
      perms: perms,
      isOwner: isOwner,
      onPk: () => openVoiceRoomBasicPkInvite(context, room),
      onOpenUser: (p) => _openUser(p, room, perms),
      onSendIstek: _sendIstek,
      istekCtrl: _istekCtrl,
      canControlMusic: canControlMusic,
      user: user,
    );
  }

  void _openUser(ChatRoomPresence user, VoiceRoomEntity room, VoiceRoomPermissions perms) {
    openVoiceRoomBasicUser(
      context,
      ref,
      room: room,
      liveKey: _liveRoomKey,
      user: user,
      perms: perms,
    );
  }

  bool _canControlMusic(
    VoiceRoomLiveState live,
    VoiceRoomEntity room,
    UserEntity? user,
    VoiceRoomPermissions perms,
  ) {
    final isDj = perms.canManageDj ||
        live.dj.canPlayMusic ||
        (user != null && room.djUserIds.contains(user.id)) ||
        live.dj.djUsers.any((u) => user != null && u.id == user.id);
    return live.dj.canControlMusic ||
        live.dj.canPlayMusic ||
        (user != null && live.dj.nowPlaying?.requestedBy?.id == user.id) ||
        perms.isRoomOwner ||
        perms.isSiteAdmin ||
        isDj;
  }

  Future<void> _sendIstek() async {
    final text = _istekCtrl.text.trim();
    if (text.isEmpty) {
      _istekCtrl.text = '!istek ';
      return;
    }
    final cmd = VoiceMusicSync.isIstekCommand(text) ? text : '!istek $text';
    await ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).sendMessage(cmd);
    if (!VoiceMusicSync.isIstekCommand(text)) {
      _istekCtrl.clear();
    }
  }

  VoiceRoomPermissions _permissions(
    UserEntity? user,
    VoiceRoomLiveState live,
    VoiceRoomEntity room,
  ) {
    ChatRoomPresence? self;
    if (user != null) {
      for (final p in live.presence) {
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
      server: live.serverPermissions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomKey = _liveRoomKey.isNotEmpty ? _liveRoomKey : widget.room.id;
    ref.watch(voiceRoomForegroundLifecycleProvider(roomKey));
    final live = ref.watch(voiceRoomLiveProvider(_liveRoomKey));
    final ui = ref.watch(voiceRoomUiProvider);
    final room = _effectiveRoom();
    final online = live.onlineCountFor(room);
    final speakerOn = ui.headphonesOn;
    final user = ref.watch(authControllerProvider).valueOrNull;
    final perms = _permissions(user, live, room);
    final canControlMusic = _canControlMusic(live, room, user, perms);
    final isOwner = perms.isRoomOwner || perms.isSiteAdmin;
    final flightQueue = ref.watch(voiceGiftFlightQueueProvider);
    final bgUrl = live.backgroundUrl ?? room.backgroundImageUrl;

    ref.listen(pkBattleRemoteProvider, (prev, next) {
      if (next == null || !isOwner || !next.isPending) return;
      final opp = next.opponentVoiceRoomId;
      final isTarget = opp == room.apiRoomKey ||
          opp == room.id ||
          opp == room.slug;
      if (!isTarget || _shownPkInviteId == next.id) return;
      _shownPkInviteId = next.id;
      unawaited(
        showVoiceRoomBasicIncomingPkInvite(
          context: context,
          ref: ref,
          room: room,
          battleId: next.id,
        ),
      );
    });

    ref.listen<VoiceRoomLiveState>(voiceRoomLiveProvider(_liveRoomKey), (prev, next) {
      if (!mounted) return;

      final toast = next.moderationToast;
      if (toast != null && toast != prev?.moderationToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(toast), duration: const Duration(seconds: 4)),
        );
      }

      final banner = next.enterBanner;
      if (banner != null && banner != prev?.enterBanner) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(banner),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final kick = next.kickStrikeWarning;
      if (kick != null && kick != prev?.kickStrikeWarning) {
        unawaited(
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(KickStrikeUi.titleFor(next.kickStrikeCount)),
              content: Text(kick),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          ),
        );
      }

      if (next.realtimeEvents.length > (prev?.realtimeEvents.length ?? 0)) {
        final latest = next.realtimeEvents.first;
        if (latest.kind == VoiceRoomRealtimeKind.moderation &&
            latest.message.toLowerCase().contains('yasaklandınız')) {
          unawaited(_leaveRoom());
        }
      }

      final q = next.pendingMusicSearchQuery;
      if (q != null &&
          q.isNotEmpty &&
          prev?.pendingMusicSearchQuery != q &&
          mounted) {
        final skipPayment = next.pendingMusicSearchSkipPayment;
        final ctrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
        unawaited(() async {
          final hit = await showMusicSearchPickerSheet(context, ref, query: q);
          ctrl.clearPendingMusicSearch();
          if (!mounted || hit == null) return;
          final err = await ctrl.submitSelectedSong(
            hit,
            withVideo: false,
            skipPayment: skipPayment,
          );
          if (!mounted || err == null) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }());
      }

      if (next.error != null && next.error != prev?.error && mounted) {
        final err = next.error!;
        if (err.contains('jeton')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
          ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).clearError();
        }
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: VoiceRoomTokens.bgDeep,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(room.displayTitle, style: const TextStyle(fontSize: 16)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: live.sseConnected ? Colors.greenAccent : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    live.sseConnected ? 'Canlı' : 'Bağlanıyor…',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$online online',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _openGiftShop(room, live.presence),
              icon: const Icon(Icons.card_giftcard_rounded),
              tooltip: 'Hediye',
            ),
            IconButton(
              onPressed: () => _openTools(
                room,
                live,
                perms,
                isOwner,
                user,
                canControlMusic,
              ),
              icon: const Icon(Icons.settings_rounded),
              tooltip: 'Ayarlar',
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            VoiceCosmicBackground(imageUrl: bgUrl),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (live.roomMuted)
                  _Banner(message: 'Oda susturulmuş (yalnızca yetkililer konuşabilir)'),
                if (_loginError != null)
                  _Banner(message: _loginError!, isError: true),
                if (_audioError != null)
                  _Banner(message: _audioError!, isError: true),
                if (_audioJoining)
                  const LinearProgressIndicator(minHeight: 2),
                if (live.loading && live.presence.isEmpty)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else ...[
                  VoiceRoomBasicModerationSection(
                    room: room,
                    liveKey: _liveRoomKey,
                    live: live,
                    perms: perms,
                    user: user,
                  ),
                  VoiceRoomBasicJoinTicker(
                    events: live.realtimeEvents,
                    messages: live.messages,
                    onlineCount: online,
                  ),
                  VoiceRoomBasicFloatingMiniPlayer(
                    room: room,
                    liveKey: _liveRoomKey,
                    live: live,
                    canControlMusic: canControlMusic,
                    perms: perms,
                  ),
                  Expanded(
                    child: VoiceRoomBasicChatFeed(messages: live.messages),
                  ),
                  if (live.error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        live.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ],
            ),
            VoiceGiftFlightOverlay(
              events: flightQueue,
              enabled: ui.giftAnimationsEnabled,
              onFinished: (id) =>
                  ref.read(voiceGiftFlightQueueProvider.notifier).dequeue(id),
            ),
            PremiumGiftFullscreenOverlay(event: _fullscreenGift),
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
        bottomNavigationBar: Material(
          elevation: 8,
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VoiceRoomBasicMessageBar(
                  controller: _messageCtrl,
                  onSend: _sendChatMessage,
                  onEmoji: () =>
                      showVoiceRoomBasicEmojiPicker(context, _messageCtrl),
                ),
                VoiceRoomBasicCompactControls(
                  isMicMuted: _isMicMuted,
                  speakerOn: speakerOn,
                  onMic: _toggleMic,
                  onSpeaker: _toggleSpeaker,
                  onLeave: _confirmLeave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isError
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(message),
      ),
    );
  }
}

/// Rota sarmalayıcı — hata sınırı ile temel sayfa.
Widget voiceRoomBasicPageWithBoundary({
  required String roomId,
  required VoiceRoomEntity room,
}) {
  return VoiceRoomErrorBoundary(
    roomId: roomId,
    child: VoiceRoomBasicPage(room: room),
  );
}
