import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:share_plus/share_plus.dart';
import '../../../../core/performance/voice_room_entry_perf.dart';
import '../utils/kick_strike_ui.dart';
import '../widgets/voice_room_error_boundary.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/auth/staff_roles.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../live/domain/entities/live_gift_event.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_my_permissions.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_realtime_event.dart';
import '../../domain/voice_official_join.dart';
import '../../../gifts/domain/session_gift_summary_builder.dart';
import '../../../gifts/presentation/widgets/session_gift_summary_sheet.dart';
import '../../../gifts/domain/gift_revenue_display.dart';
import '../../../gifts/presentation/sync/gift_event_listener.dart';
import '../providers/staff_entrance_marquee_provider.dart';
import '../providers/voice_gift_combo_tracker.dart';
import '../providers/voice_gift_leaderboard_provider.dart';
import '../providers/voice_recent_gifts_provider.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_gift_providers.dart';
import '../audio/voice_room_audio_coordinator.dart';
import '../audio/voice_trtc_engine.dart';
import '../audio/voice_room_music_audio_session.dart';
import '../providers/chat_room_providers.dart';
import '../providers/voice_room_audio_providers.dart';
import '../providers/voice_room_ui_provider.dart';
import '../../../../core/auth/staff_roles.dart';
import '../sheets/voice_room_commands_panel.dart';
import '../utils/voice_room_permissions.dart';
import '../utils/voice_room_error_display.dart';
import '../utils/voice_room_speak_access.dart';
import '../theme/voice_room_tokens.dart';
import '../../../gifts/presentation/engine/voice_gift_ambient_overlay.dart';
import '../widgets/premium/voice_gift_stage_overlays.dart';
import '../widgets/premium_2026/voice_cosmic_background.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../../cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../../cosmetics/presentation/widgets/cosmetic_entrance_overlay.dart';
import '../../../vip_gold/presentation/widgets/vip_entrance_overlay.dart';
import 'voice_room_basic_moderation_section.dart';
import '../sheets/voice_room_menu_sheet.dart';
import 'voice_room_basic_premium_section.dart';
import '../../music/presentation/widgets/music_search_picker_sheet.dart';
import '../sheets/music_mode_picker_sheet.dart';
import '../utils/voice_music_access.dart';
import '../sheets/voice_room_sheets.dart';
import '../sheets/voice_room_management_panel.dart';
import '../widgets/premium_2026/voice_live_action_bar_2026.dart';
import '../widgets/premium_2026/voice_live_header_2026.dart';
import '../widgets/premium_2026/voice_online_gift_box.dart';
import '../../../../core/navigation/wallet_navigation.dart';
import '../widgets/voice_room/voice_room_now_playing_bar.dart';
import '../../../gifts/presentation/widgets/gift_battle_strip.dart';
import '../../../gifts/presentation/widgets/first_gifter_badge.dart';
import '../../../gifts/presentation/widgets/gift_goal_bar.dart';

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
  final _messageCtrl = TextEditingController();
  StreamSubscription<LiveGiftEvent>? _giftSub;
  LiveGiftEvent? _fullscreenGift;
  var _showVipEntrance = false;
  var _vipEntrancePlayed = false;
  int? _lastSelfSeatIndex;
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
    _messageCtrl.dispose();
    _giftSub?.cancel();
    _giftSub = null;
    ref.read(voiceRoomGiftRealtimeProvider).stop();
    ref.read(pkBattleRemoteProvider.notifier).clear();
    final liveKey = _pinnedLiveRoomKey;
    if (liveKey != null && liveKey.isNotEmpty) {
      unawaited(
        ref
            .read(voiceRoomLiveProvider(liveKey).notifier)
            .leaveRoomSession(source: 'basic_dispose'),
      );
    }
    final audio = _audio;
    _audio = null;
    if (audio != null) {
      unawaited(audio.leave());
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
      final roomId = room.apiRoomKey;
      if (!ref.read(voiceRoomLiveProvider(_liveRoomKey)).backendSyncReady) {
        final deadline = DateTime.now().add(const Duration(milliseconds: 1500));
        while (DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
          if (ref.read(voiceRoomLiveProvider(_liveRoomKey)).backendSyncReady) {
            break;
          }
        }
      }
      final sync = ref.read(voiceRoomLiveProvider(_liveRoomKey));
      final staffBypass = StaffRoles.isSiteAdminUser(
        role: user.role,
        username: user.username,
      );
      _audio!.setStaffBypassVoiceApi(staffBypass);
      await _audio!.join(
        roomId: roomId,
        remote: ref.read(chatRoomRemoteProvider),
        enableMic: false,
        staffBypassVoiceApi: staffBypass,
        userId: user.id,
        backendTrtc: sync.roomTrtc,
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

  Future<void> _toggleMic() async {
    if (_audio == null || !_audioReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses bağlantısı hazır değil')),
      );
      return;
    }
    final muted = !_isMicMuted;
    if (!muted) {
      final micOk = await VoiceTrtcEngine.requestMicrophonePermission();
      if (!micOk) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Mikrofon izni gerekli. Ayarlardan mikrofonu açıp tekrar deneyin.',
            ),
          ),
        );
        return;
      }
      final user = ref.read(authControllerProvider).valueOrNull;
      final live = ref.read(voiceRoomLiveProvider(_liveRoomKey));
      final room = _effectiveRoom();
      ChatRoomPresence? selfPresence;
      for (final p in live.presence) {
        if (p.id == user?.id) {
          selfPresence = p;
          break;
        }
      }
      final perms = VoiceRoomPermissions.forUser(
        user: user,
        room: room,
        selfPresence: selfPresence,
        server: live.serverPermissions,
      );
      if (!VoiceRoomSpeakAccess.canSpeak(
        user: user,
        perms: perms,
        room: room,
        presence: live.presence,
      )) {
        final notifier = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
        final seated = await notifier.ensureSelfOnSeatForMic();
        if (!mounted) return;
        if (!seated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Konuşmak için boş bir koltuğa oturmalısınız'),
            ),
          );
          return;
        }
        await notifier.refresh();
      }
    }
    try {
      await _audio!.setMicEnabled(!muted);
      if (mounted) setState(() => _isMicMuted = muted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  void _onChatChanged(String text) {
    ref
        .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
        .notifyTyping(text.trim().isNotEmpty);
  }

  void _toggleSpeaker() {
    ref.read(voiceRoomUiProvider.notifier).toggleHeadphones();
    _audio?.setHeadphonesOn(ref.read(voiceRoomUiProvider).headphonesOn);
    if (mounted) setState(() {});
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
    final event = ref.read(voiceGiftComboTrackerProvider.notifier).enrich(raw);
    ref.read(voiceSessionGiftLeaderboardProvider.notifier).record(event);

    if (event.jetonAmount >= 1000) {
      ref.read(staffEntranceMarqueeProvider.notifier).enqueueBigGift(
            senderName: event.senderName,
            receiverName: event.receiverName,
            jeton: event.jetonAmount,
            giftName: event.giftName,
          );
    }
  }

  void _maybeShowVipEntrance(UserEntity user) {
    if (_vipEntrancePlayed || !mounted) return;
    final cosmetic = ref.read(resolvedEntranceEffectProvider);
    final tier = ref.read(vipTierProvider);
    if (cosmetic == null && !tier.hasEntranceFx) return;
    _vipEntrancePlayed = true;
    if (mounted) setState(() => _showVipEntrance = true);
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

    final room = _effectiveRoom();
    final user = ref.read(authControllerProvider).valueOrNull;
    final summary = SessionGiftSummaryBuilder.forVoiceRoom(
      ref: ref,
      roomTitle: room.nameTr,
      ownerUserId: room.ownerId,
      ownerDisplayName: room.ownerName,
      myUserId: user?.id,
      myDisplayName: user?.display,
    );
    await SessionGiftSummaryBuilder.refreshWalletIfRecipient(ref, summary);

    unawaited(liveCtrl.leaveRoomSession(source: 'basic_leave'));
    if (audio != null) {
      unawaited(audio.leave());
    }

    if (!mounted) return;
    if (summary.hasData) {
      await showSessionGiftSummarySheet(context, summary: summary);
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

  void _openManagementPanel(
    VoiceRoomEntity room,
    VoiceRoomLiveState live,
    VoiceRoomPermissions perms,
    bool isOwner,
  ) {
    showVoiceRoomManagementPanel(
      context,
      ref,
      room: room,
      live: live,
      perms: perms,
      isOwner: isOwner,
      onUserTap: (u) => _openUser(u, room, perms),
      onPkInvite: () => openVoiceRoomBasicPkInvite(context, room),
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

  /// Chat'te isme tek dokunuş → "@kullanıcı adı " mesaj kutusuna eklenir.
  void _insertMention(String name) {
    final n = name.trim();
    if (n.isEmpty) return;
    final existing = _messageCtrl.text;
    final needsSpace = existing.isNotEmpty && !existing.endsWith(' ');
    final mention = '@$n ';
    _messageCtrl.text = '$existing${needsSpace ? ' ' : ''}$mention';
    _messageCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageCtrl.text.length),
    );
  }

  /// Chat'te isme çift dokunuş → kullanıcı yetkileri (moderasyon) açılır.
  void _openUserById(
    String userId,
    VoiceRoomLiveState live,
    VoiceRoomEntity room,
    VoiceRoomPermissions perms,
  ) {
    ChatRoomPresence? target;
    for (final p in live.presence) {
      if (p.id == userId) {
        target = p;
        break;
      }
    }
    if (target != null) _openUser(target, room, perms);
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
      staffSiteAdmin: ref.read(staffAccessProvider).isFounder,
      walletRole: ref.read(staffAccessProvider).siteRole ??
          ref.read(walletBalancesProvider).valueOrNull?.role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomKey = _liveRoomKey.isNotEmpty ? _liveRoomKey : widget.room.id;
    ref.watch(voiceRoomForegroundLifecycleProvider(roomKey));
    ref.watch(
      voiceRoomLiveProvider(_liveRoomKey).select(_BasicLiveShell.fromState),
    );
    final live = ref.read(voiceRoomLiveProvider(_liveRoomKey));
    final roomErrorBanner =
        VoiceRoomErrorDisplay.bannerMessage(live.error, live: live);
    final ui = ref.watch(voiceRoomUiProvider);
    final room = _effectiveRoom();
    final online = live.onlineCountFor(room);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final perms = _permissions(user, live, room);
    final canControlMusic = _canControlMusic(live, room, user, perms);
    final isOwner = perms.isRoomOwner || perms.isSiteAdmin;
    final sessionKey =
        room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    final bgUrl = live.backgroundUrl ?? room.backgroundImageUrl;
    final jeton = ref.watch(
      walletBalancesProvider.select((a) => a.valueOrNull?.jeton ?? 0),
    );
    String? hostAvatar;
    final ownerId = room.ownerId;
    if (ownerId != null) {
      for (final p in live.presence) {
        if (p.id == ownerId) {
          hostAvatar = p.image;
          break;
        }
      }
    }

    ref.listen<VoiceRoomLiveState>(voiceRoomLiveProvider(_liveRoomKey), (prev, next) {
      if (!mounted) return;

      final toast = next.moderationToast;
      if (toast != null && toast != prev?.moderationToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(toast), duration: const Duration(seconds: 4)),
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
          prev?.pendingMusicSearchQuery != q &&
          mounted) {
        final skipPayment = next.pendingMusicSearchSkipPayment;
        final ctrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
        final dj = next.dj;
        ctrl.clearPendingMusicSearch();
        unawaited(
          showMusicSearchPickerSheet(
            context,
            ref,
            query: q,
            onSelected: (hit) async {
              if (!mounted) return;
              final withVideo = await showMusicModePickerSheet(
                context,
                audioCost: VoiceMusicAccess.audioRequestCost(dj),
                videoCost: VoiceMusicAccess.videoRequestCost(dj),
                songTitle: hit.title,
              );
              if (!mounted || withVideo == null) return;
              final messenger = ScaffoldMessenger.of(context);
              final err = await ctrl.submitSelectedSong(
                hit,
                withVideo: withVideo,
                skipPayment: skipPayment,
              );
              if (!mounted) return;
              if (err != null) {
                messenger.showSnackBar(SnackBar(content: Text(err)));
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text('«${hit.title}» çalmaya başladı')),
                );
              }
            },
          ),
        );
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

      if (next.openCommandsPanel && !(prev?.openCommandsPanel ?? false)) {
        ref
            .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
            .clearOpenCommandsPanel();
        if (!mounted) return;
        final room = _effectiveRoom();
        final userNow = ref.read(authControllerProvider).valueOrNull;
        final permsNow = _permissions(userNow, next, room);
        final owner = permsNow.isRoomOwner || permsNow.isSiteAdmin;
        unawaited(
          showVoiceRoomCommandsPanel(
            context,
            ref,
            room: room,
            perms: permsNow,
            isOwner: owner,
          ),
        );
      }

      if (_audioReady) {
        final user = ref.read(authControllerProvider).valueOrNull;
        if (user != null) {
          final room = _effectiveRoom();
          ChatRoomPresence? selfPresence;
          for (final p in next.presence) {
            if (p.id == user.id) {
              selfPresence = p;
              break;
            }
          }
          final perms = VoiceRoomPermissions.forUser(
            user: user,
            room: room,
            selfPresence: selfPresence,
            server: next.serverPermissions,
            staffSiteAdmin: ref.read(staffAccessProvider).isFounder,
            walletRole: ref.read(staffAccessProvider).siteRole ??
                ref.read(walletBalancesProvider).valueOrNull?.role,
          );
          final canSpeak = VoiceRoomSpeakAccess.canSpeak(
            user: user,
            perms: perms,
            room: room,
            presence: next.presence,
          );
          final seat = selfPresence?.seatIndex;
          if (canSpeak &&
              seat != null &&
              seat != _lastSelfSeatIndex &&
              _audioReady &&
              _isMicMuted) {
            _audio?.setMicEnabled(true);
            if (mounted) setState(() => _isMicMuted = false);
          }
          _lastSelfSeatIndex = seat;
          if (!canSpeak && !_isMicMuted) {
            _audio?.setMicEnabled(false);
            if (mounted) setState(() => _isMicMuted = true);
          }
        }
      }
    });

    return GiftEventListener(
      sessionKey: sessionKey,
      isHost: isOwner,
      child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: VoiceRoomTokens.bgDeep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            VoiceCosmicBackground(imageUrl: bgUrl),
            Positioned.fill(
              child: VoiceGiftAmbientOverlay(sessionKey: sessionKey),
            ),
            SafeArea(
              bottom: false,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VoiceLiveHeader2026(
                  room: room,
                  onlineCount: online,
                  coinBalance: jeton,
                  hostAvatarUrl: hostAvatar,
                  onBack: () => unawaited(_confirmLeave()),
                  onExit: () => unawaited(_confirmLeave()),
                  onAudience: () => showVoiceSpeakerListSheet(
                    context,
                    presence: live.presence,
                    room: room,
                    onUserTap: (u) => _openUser(u, room, perms),
                  ),
                  onCoinsTap: () => openJetonStore(context, ref: ref),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: VoiceOnlineGiftBox(
                      onlineCount: online,
                      onTap: () => showVoiceSpeakerListSheet(
                        context,
                        presence: live.presence,
                        room: room,
                        onUserTap: (u) => _openUser(u, room, perms),
                      ),
                    ),
                  ),
                ),
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
                  // Müzik yalnızca ses — video şeridi kaldırıldı (donma önlenir).
                  // Koltuk altı "şu an çalan şarkı" şeridi (yeşil kutu).
                  VoiceRoomNowPlayingBar(
                    roomKey: _liveRoomKey,
                    canControl: canControlMusic,
                  ),
                  // Aktif hediye savaşı — canlı skor + geri sayım.
                  GiftBattleStrip(
                    context: 'voice_room',
                    contextId: _liveRoomKey,
                  ),
                  // Aktif hediye hedefi — ilerleme çubuğu + kutlama.
                  GiftGoalBar(
                    context: 'voice_room',
                    contextId: _liveRoomKey,
                  ),
                  // Efsane İlk Destekçi rozeti (varsa).
                  FirstGifterBadge(
                    context: 'voice_room',
                    contextId: _liveRoomKey,
                  ),
                  Expanded(
                    child: VoiceRoomBasicChatFeed(
                      liveKey: _liveRoomKey,
                      onMention: (userId, name) => _insertMention(name),
                      onUserPerms: (userId, name) =>
                          _openUserById(userId, live, room, perms),
                    ),
                  ),
                  if (roomErrorBanner != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        roomErrorBanner,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  VoiceRoomBasicMessageBar(
                    controller: _messageCtrl,
                    onSend: _sendChatMessage,
                    onChanged: _onChatChanged,
                    presence: live.presence,
                    selfUserId: user?.id,
                    onEmoji: () =>
                        showVoiceRoomBasicEmojiPicker(context, _messageCtrl),
                  ),
                  VoiceLiveActionBar2026(
                    micOn: !_isMicMuted,
                    micEnabled: _audioReady && !_audioJoining,
                    onMic: _toggleMic,
                    onGift: () => _openGiftShop(room, live.presence),
                    onSettings: () => _openManagementPanel(
                      room,
                      live,
                      perms,
                      isOwner,
                    ),
                    headphonesOn: ui.headphonesOn,
                    onToggleAudioOutput: _toggleSpeaker,
                    onInvite: () => unawaited(_shareRoom(room)),
                  ),
                ],
              ],
            ),
            ),
            VoiceGiftHudOverlays(sessionKey: sessionKey),
            if (_showVipEntrance && user != null)
              Builder(
                builder: (context) {
                  final name = user.displayName?.trim().isNotEmpty == true
                      ? user.displayName!.trim()
                      : user.username;
                  final cosmetic = ref.watch(resolvedEntranceEffectProvider);
                  if (cosmetic != null) {
                    return CosmeticEntranceOverlay(
                      userName: name,
                      effectKind: cosmetic.effectKind,
                      onFinished: () {
                        if (mounted) setState(() => _showVipEntrance = false);
                      },
                    );
                  }
                  return VipEntranceOverlay(
                    tier: ref.watch(vipTierProvider),
                    userName: name,
                    onFinished: () {
                      if (mounted) setState(() => _showVipEntrance = false);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _shareRoom(VoiceRoomEntity room) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Canlifal sesli oda: ${room.displayTitle}\n'
            'https://canlifal.com/voice-room/${room.slug.isNotEmpty ? room.slug : room.id}',
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

/// Oda gövdesi rebuild sınırı — sohbet mesajları hariç.
class _BasicLiveShell {
  const _BasicLiveShell({
    required this.presence,
    required this.dj,
    required this.serverPermissions,
    required this.backgroundUrl,
    required this.loading,
    required this.error,
    required this.roomMuted,
    required this.realtimeEvents,
  });

  factory _BasicLiveShell.fromState(VoiceRoomLiveState s) => _BasicLiveShell(
        presence: s.presence,
        dj: s.dj,
        serverPermissions: s.serverPermissions,
        backgroundUrl: s.backgroundUrl,
        loading: s.loading,
        error: s.error,
        roomMuted: s.roomMuted,
        realtimeEvents: s.realtimeEvents,
      );

  final List<ChatRoomPresence> presence;
  final ChatRoomDjState dj;
  final ChatRoomMyPermissions? serverPermissions;
  final String? backgroundUrl;
  final bool loading;
  final String? error;
  final bool roomMuted;
  final List<VoiceRoomRealtimeEvent> realtimeEvents;

  @override
  bool operator ==(Object other) =>
      other is _BasicLiveShell &&
      identical(presence, other.presence) &&
      dj == other.dj &&
      serverPermissions == other.serverPermissions &&
      backgroundUrl == other.backgroundUrl &&
      loading == other.loading &&
      error == other.error &&
      roomMuted == other.roomMuted &&
      identical(realtimeEvents, other.realtimeEvents);

  @override
  int get hashCode => Object.hash(
        presence,
        dj,
        serverPermissions,
        backgroundUrl,
        loading,
        error,
        roomMuted,
        realtimeEvents,
      );
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
