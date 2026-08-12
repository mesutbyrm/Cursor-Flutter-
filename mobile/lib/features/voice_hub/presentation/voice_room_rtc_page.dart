import 'dart:async';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../gifts/domain/session_gift_summary.dart';
import '../../gifts/domain/session_gift_summary_builder.dart';
import '../../gifts/presentation/widgets/session_gift_summary_sheet.dart';

import '../../../core/config/env.dart';
import '../../../core/auth/staff_roles.dart';
import '../../../core/performance/voice_room_entry_perf.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/widgets/cached_cover_image.dart';
import '../../../core/navigation/wallet_navigation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/voice_event_log.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import '../../live/domain/entities/live_gift_event.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/presentation/providers/live_providers.dart';
import '../data/services/voice_room_debug_log.dart';
import '../domain/entities/voice_room_realtime_event.dart';
import '../domain/voice_official_join.dart';
import '../../gifts/domain/premium_gift_catalog_2026.dart';
import '../../gifts/presentation/widgets/gift_battle_strip.dart';
import '../../gifts/presentation/widgets/lucky_gift_wins_ticker.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../vip_gold/domain/vip_tier.dart';
import '../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../cosmetics/presentation/widgets/cosmetic_entrance_overlay.dart';
import '../../vip_gold/presentation/providers/user_room_profile_provider.dart';
import '../../vip_gold/presentation/widgets/vip_entrance_overlay.dart';
import '../../trtc/presentation/trtc_room_manager.dart';
import '../domain/entities/chat_room_dj_state.dart';
import '../domain/entities/chat_room_message.dart';
import '../domain/entities/chat_room_presence.dart';
import '../domain/entities/chat_room_sse_event.dart';
import '../domain/entities/chat_room_my_permissions.dart';
import '../domain/entities/voice_room_seat_slot.dart';
import 'audio/voice_room_audio_coordinator.dart';
import 'audio/voice_room_music_audio_session.dart';
import 'providers/chat_room_providers.dart';
import '../music/presentation/providers/room_music_providers.dart';
import '../music/presentation/widgets/room_song_mini_player.dart';
import '../music/presentation/widgets/music_search_picker_sheet.dart';
import 'sheets/music_mode_picker_sheet.dart';
import 'sheets/voice_room_hub_settings.dart';
import 'providers/pk_battle_remote_provider.dart';
import '../domain/pk/pk_duration_options.dart';
import '../domain/pk/pk_opponent_room_filter.dart';
import 'utils/voice_room_image_prefetch.dart';
import 'utils/voice_room_seat_capacity.dart';
import 'providers/voice_gift_providers.dart';
import 'providers/voice_room_audio_providers.dart';
import 'providers/voice_session_phase_provider.dart';
import '../domain/voice/voice_session_phase.dart';
import 'providers/voice_room_diagnostic_provider.dart';
import 'providers/voice_room_sse_provider.dart';
import 'providers/voice_room_ui_provider.dart';
import 'sheets/voice_room_management_panel.dart';
import 'sheets/voice_room_moderation_sheet.dart';
import 'sheets/voice_room_sheets.dart';
import 'utils/voice_music_access.dart';
import 'theme/voice_room_tokens.dart';
import 'utils/voice_room_permissions.dart';
import 'utils/voice_room_error_display.dart';
import 'utils/voice_room_speak_access.dart';
import 'utils/voice_room_session_exit.dart';
import 'basic/voice_room_basic_moderation_section.dart';
import 'utils/voice_room_responsive_metrics.dart';
import '../../gifts/presentation/engine/gift_engine_overlay.dart';
import '../../gifts/presentation/widgets/gift_stage_layout.dart';
import '../../gifts/presentation/sync/gift_session_controller.dart';
import 'widgets/premium/voice_gift_stage_overlays.dart';
import 'widgets/premium/voice_glass.dart';
import 'widgets/premium_2026/voice_cosmic_background.dart';
import 'widgets/voice_room/voice_room_spec_footer.dart';
import 'widgets/voice_room/voice_room_music_background_layer.dart';
import 'sheets/voice_room_commands_panel.dart';
import 'widgets/premium_2026/voice_room_persistent_duyuru.dart';
import 'widgets/premium_2026/voice_gift_announcement_ticker.dart';
import '../../gifts/presentation/sync/gift_event_listener.dart';
import 'widgets/voice_room/voice_room_duyuru_ticker.dart';
import 'utils/kick_strike_ui.dart';
import 'audio/voice_trtc_engine.dart';
import 'widgets/voice_room/voice_room_staff_join_banner.dart';
import 'widgets/premium_2026/voice_web_chat_overlay.dart';
import 'widgets/premium_2026/voice_web_owner_stage.dart';
import 'widgets/premium_2026/voice_web_room_header.dart';
import 'widgets/voice_room/voice_room_center_music_panel.dart';
import 'widgets/voice_room/voice_room_music_queue_mini_card.dart';
import 'widgets/voice_room/voice_room_music_request_fab.dart';
import 'widgets/voice_room/voice_room_bottom_dock.dart';
import 'widgets/voice_room_error_boundary.dart';
import 'sheets/voice_youtube_song_sheet.dart';
import 'widgets/premium_2026/voice_pk_invite_banner.dart';

/// Sesli sohbet odası — Tencent TRTC + canlifal.com chat API.
class VoiceRoomRtcPage extends ConsumerStatefulWidget {
  const VoiceRoomRtcPage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<VoiceRoomRtcPage> createState() => _VoiceRoomRtcPageState();
}

class _VoiceRoomRtcPageState extends ConsumerState<VoiceRoomRtcPage> {
  VoiceRoomAudioCoordinator? _audio;
  final _messageCtrl = TextEditingController();
  final _chatScrollCtrl = ScrollController();
  var _scrollChatToLatest = false;
  var _audioJoining = false;
  var _audioJoinInFlight = false;
  var _audioReady = false;
  String? _audioError;
  String? _loginError;
  var _isMicMuted = false;
  var _micAutoMutedByMusic = false;
  var _leaving = false;
  var _leaveSessionStarted = false;
  var _forcedExitHandled = false;
  var _musicSearchOpen = false;
  LiveGiftEvent? _fullscreenGift;
  final _messageFocus = FocusNode();
  var _showVipEntrance = false;
  var _vipEntrancePlayed = false;
  var _giftRealtimeStarted = false;
  int? _lastSelfSeatIndex;
  /// Riverpod oturum anahtarı — metadata değişince provider dispose olmasın.
  String? _pinnedLiveRoomKey;

  String get _liveRoomKey {
    final pinned = _pinnedLiveRoomKey?.trim();
    if (pinned != null && pinned.isNotEmpty) return pinned;
    final room = _effectiveRoom();
    final key = room.apiRoomKey.isNotEmpty
        ? room.apiRoomKey
        : widget.room.apiRoomKey;
    if (key.isNotEmpty) _pinnedLiveRoomKey = key;
    return key;
  }

  @override
  void initState() {
    super.initState();
    if (widget.room.apiRoomKey.isNotEmpty) {
      _pinnedLiveRoomKey = widget.room.liveKey;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomKey = widget.room.apiRoomKey;
      VoiceRoomDebugLog.routeEnter(
        roomId: roomKey.isNotEmpty ? roomKey : widget.room.id,
        slug: widget.room.slug,
        source: 'rtc_page',
      );
      ref.read(voiceRoomDiagnosticProvider.notifier).resetForRoom(
            roomKey.isNotEmpty ? roomKey : widget.room.id,
          );
      unawaited(_logJwtStatus());
      if (roomKey.isEmpty) {
        unawaited(ref.read(voiceRoomsProvider.future));
      }
      ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).ensureActiveSession();
      _startGiftRealtimePoll();
      final user = ref.read(authControllerProvider).valueOrNull;
      if (user != null) _maybeShowEntrance(user);
      unawaited(_joinAudioBackground());
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

  VoiceRoomEntity _displayRoom(List<VoiceRoomEntity>? rooms) {
    final synced = _roomSynced(rooms);
    if (synced.apiRoomKey.isNotEmpty) return synced;
    if (widget.room.apiRoomKey.isNotEmpty) return widget.room;
    return synced;
  }

  VoiceRoomEntity _displayRoomFromSingle(VoiceRoomEntity? synced) {
    if (synced != null && synced.apiRoomKey.isNotEmpty) return synced;
    if (widget.room.apiRoomKey.isNotEmpty) return widget.room;
    return synced ?? widget.room;
  }

  VoiceRoomEntity _effectiveRoom() {
    return _displayRoom(ref.read(voiceRoomsProvider).valueOrNull);
  }

  @override
  void dispose() {
    _giftRealtimeStarted = false;
    _messageCtrl.dispose();
    _chatScrollCtrl.dispose();
    _messageFocus.dispose();
    if (!_leaveSessionStarted && _liveRoomKey.isNotEmpty) {
      unawaited(
        ref
            .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
            .leaveRoomSession(
              source: 'rtc_dispose',
              awaitBackend: true,
              force: true,
            )
            .timeout(const Duration(seconds: 6))
            .catchError((_) {}),
      );
    } else if (_liveRoomKey.isEmpty) {
      final audio = _audio;
      _audio = null;
      if (audio != null) unawaited(audio.leave());
    }
    ref.read(voiceRoomGiftRealtimeProvider).stop();
    ref.read(pkBattleRemoteProvider.notifier).clear();
    super.dispose();
  }

  Future<void> _logJwtStatus() async {
    final token = await ref.read(tokenStorageProvider).readAccess();
    final hasJwt = token != null && token.isNotEmpty;
    VoiceRoomDebugLog.jwtStatus(
      hasToken: hasJwt,
      tokenLength: token?.length,
    );
    ref.read(voiceRoomDiagnosticProvider.notifier).setJwt(hasJwt: hasJwt);
  }

  Future<void> _prefetchRoomImages() async {
    if (!mounted) return;
    final room = widget.room;
    final bg = ref.read(voiceRoomLiveProvider(_liveRoomKey)).backgroundUrl ??
        room.backgroundImageUrl;
    if (bg == null || bg.isEmpty) return;
    await prefetchVoiceRoomImages(context, primaryUrl: bg);
  }

  void _showEmojiPicker(BuildContext ctx, TextEditingController ctrl) {
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

  void _sendChatMessage(VoiceRoomEntity room) {
    final text = VoiceOfficialJoin.normalizeCommandInput(
      _messageCtrl.text.trim(),
    );
    if (text.isEmpty) return;
    _messageCtrl.clear();
    _messageFocus.requestFocus();
    setState(() => _scrollChatToLatest = true);
    unawaited(
      ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).sendMessage(text),
    );
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _scrollChatToLatest = false);
    });
  }

  void _openUserFromChat(
    String userId,
    String name,
    ChatRoomMessage message, {
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
    required VoiceRoomPermissions perms,
    required bool isOwner,
  }) {
    ChatRoomPresence? found;
    for (final e in live.presence) {
      if (e.id == userId) {
        found = e;
        break;
      }
    }
    final user = message.user;
    found ??= ChatRoomPresence(
      id: userId,
      name: user?.name ?? name,
      nickname: user?.nickname,
      image: user?.image,
      chatRole: user?.chatRole,
      roleSymbol: user?.roleSymbol,
      membership: user?.membership,
    );
    _openUser(found, perms: perms, room: room, isOwner: isOwner);
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
      final perms = _perms(user, live.presence, server: live.serverPermissions);
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
      await _audio?.setMicEnabled(!muted);
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

  void _toggleHeadphones() {
    ref.read(voiceRoomUiProvider.notifier).toggleHeadphones();
    final on = ref.read(voiceRoomUiProvider).headphonesOn;
    _audio?.setHeadphonesOn(on);
    unawaited(
      ref
          .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
          .applyAudioOutputGate(speakerOn: on),
    );
  }

  void _startGiftRealtimePoll() {
    if (_giftRealtimeStarted) return;
    final room = _effectiveRoom();
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (key.isEmpty) return;
    _giftRealtimeStarted = true;
    ref.read(voiceRoomGiftRealtimeProvider).start(key);
    ref.read(voiceRoomDiagnosticProvider.notifier).setSocket(true);
  }

  void _startGiftRealtime() => _startGiftRealtimePoll();

  Future<UserEntity?> _waitForAuth({Duration timeout = const Duration(seconds: 1)}) async {
    final cached = ref.read(authControllerProvider).valueOrNull;
    if (cached != null) return cached;
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoading) return auth.valueOrNull;
    try {
      return await ref.read(authControllerProvider.future).timeout(timeout);
    } catch (_) {
      return ref.read(authControllerProvider).valueOrNull;
    }
  }

  void _maybeShowEntrance(UserEntity user) {
    if (_vipEntrancePlayed || !mounted) return;
    final cosmetic = ref.read(resolvedEntranceEffectProvider);
    final tier = ref.read(vipTierProvider);
    if (cosmetic == null && !tier.hasEntranceFx) return;
    _vipEntrancePlayed = true;
    if (mounted) setState(() => _showVipEntrance = true);
  }

  Future<void> _joinAudioBackground() async {
    if (!mounted || _audioJoinInFlight || _audioReady) return;
    _audioJoinInFlight = true;
    setState(() {
      _audioJoining = true;
      _audioError = null;
    });

    final user = await _waitForAuth(timeout: VoiceRoomEntryPerf.entryBudget);
    if (!mounted) return;
    if (user == null) {
      if (mounted) {
        setState(() {
          _audioJoining = false;
          _loginError = 'Odaya girmek için giriş yapın';
        });
      }
      _audioJoinInFlight = false;
      return;
    }

    setState(() => _loginError = null);
    _maybeShowEntrance(user);

    var room = _effectiveRoom();
    if (room.apiRoomKey.isEmpty && widget.room.apiRoomKey.isNotEmpty) {
      room = widget.room;
      _pinnedLiveRoomKey = room.liveKey;
    }
    if (room.apiRoomKey.isEmpty) {
      ref.invalidate(voiceRoomsProvider);
      try {
        final rooms = await ref
            .read(voiceRoomsProvider.future)
            .timeout(const Duration(seconds: 3));
        room = _roomSynced(rooms);
        if (room.apiRoomKey.isNotEmpty) {
          _pinnedLiveRoomKey = room.liveKey;
        }
      } catch (_) {}
    }
    if (room.apiRoomKey.isEmpty) {
      if (mounted) {
        setState(() {
          _audioJoining = false;
          _audioError = 'Oda bilgisi yükleniyor…';
        });
      }
      _audioJoinInFlight = false;
      return;
    }

    _startGiftRealtime();

    _audio = ref.read(voiceRoomAudioCoordinatorProvider);
    if (!_audio!.isSupported) {
      if (mounted) {
        setState(() {
          _audioJoining = false;
          _audioError = 'Ses bağlantısı bu cihazda desteklenmiyor; sohbet çalışır';
        });
      }
      _audioJoinInFlight = false;
      return;
    }

    try {
      final roomId = room.apiRoomKey;
      VoiceEventLog.trtcConnecting(roomId: roomId);
      final live = ref.read(voiceRoomLiveProvider(_liveRoomKey));
      if (!live.backendSyncReady) {
        if (mounted) {
          setState(() {
            _audioJoining = true;
            _audioError = null;
          });
        }
        final deadline = DateTime.now().add(const Duration(milliseconds: 1500));
        while (DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          if (!mounted) return;
          final snap = ref.read(voiceRoomLiveProvider(_liveRoomKey));
          if (snap.backendSyncReady) break;
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
      if (mounted) {
        VoiceEventLog.trtcConnected(roomId: roomId);
        ref.read(voiceRoomDiagnosticProvider.notifier).setTrtc(
              roomId: sync.roomTrtc?.effectiveStrRoomId ?? roomId,
              result: 1,
            );
        ref.read(voiceRoomDiagnosticProvider.notifier).setAudioReady(true);
        unawaited(VoiceRoomMusicAudioSession.activateForPlayback());
        setState(() {
          _audioJoining = false;
          _audioReady = true;
          _isMicMuted = !_audio!.micOn;
        });
        ref.read(voiceRoomTrtcMusicMixerProvider).bind(_audio!.trtcManager);
        _wireAudioReconnectCallbacks();
        _startGiftRealtime();
        _audio?.setHeadphonesOn(ref.read(voiceRoomUiProvider).headphonesOn);
        unawaited(_connectPkBattle());
        // Agora kamera yalnızca kullanıcı açtığında — oda girişinde otomatik değil.
      }
    } catch (e) {
      if (mounted) {
        final msg = ApiException.userMessage(e);
        ref.read(voiceRoomDiagnosticProvider.notifier).setError(msg);
        ref.read(voiceRoomDiagnosticProvider.notifier).setAudioReady(false);
        setState(() {
          _audioJoining = false;
          _audioError = msg;
        });
        _startGiftRealtime();
      }
    } finally {
      _audioJoinInFlight = false;
      if (mounted && _audioJoining) {
        setState(() => _audioJoining = false);
      }
    }
  }

  void _wireAudioReconnectCallbacks() {
    final audio = _audio;
    if (audio == null) return;
    audio.onReconnecting = () {
      if (!mounted || _leaving) return;
      ref.read(voiceSessionPhaseProvider.notifier).transitionTo(
            VoiceSessionPhase.reconnecting,
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ses bağlantısı koptu — yeniden bağlanılıyor…'),
          duration: Duration(seconds: 2),
        ),
      );
    };
    audio.onReconnected = () {
      if (!mounted || _leaving) return;
      ref.read(voiceSessionPhaseProvider.notifier).transitionTo(
            VoiceSessionPhase.connected,
          );
    };
  }

  Future<void> _connectPkBattle() async {
    if (!mounted) return;
    final r = _effectiveRoom();
    final roomKey = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
    if (roomKey.isEmpty) return;
    final remote = ref.read(pkBattleRemoteProvider.notifier);
    unawaited(remote.loadRoomBattle(
      roomKey,
      alternateRoomId: r.slug != roomKey ? r.slug : null,
    ));
  }

  Future<void> _leaveRoom() async {
    if (_leaving) return;
    _leaving = true;
    _leaveSessionStarted = true;
    final liveKey = _liveRoomKey;

    ref.read(voiceRoomTrtcMusicMixerProvider).bind(null);
    ref.read(voiceRoomTrtcMusicMixerProvider).stop();
    ref.read(voiceRoomAudioCoordinatorProvider).setReconnectSuspended(true);
    _audio = null;

    final liveNotifier = ref.read(voiceRoomLiveProvider(liveKey).notifier);
    final live = ref.read(voiceRoomLiveProvider(liveKey));
    final room = _effectiveRoom();
    final user = ref.read(authControllerProvider).valueOrNull;
    SessionGiftSummary? leaveSummary;
    if (user != null) {
      leaveSummary = SessionGiftSummaryBuilder.forVoiceRoom(
        ref: ref,
        roomTitle: room.displayTitle,
        ownerUserId: live.ownerId ?? room.ownerId,
        ownerDisplayName: room.ownerName,
        myUserId: user.id,
        myDisplayName: user.display,
      );
    }

    try {
      await liveNotifier
          .leaveRoomSession(
            source: 'rtc_leave',
            awaitBackend: true,
            force: true,
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    if (!mounted) {
      _leaving = false;
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/voice-rooms');
    }

    if (leaveSummary != null && leaveSummary.hasData) {
      final rootCtx = rootNavigatorKey.currentContext;
      if (rootCtx != null && rootCtx.mounted) {
        await showSessionGiftSummarySheet(rootCtx, summary: leaveSummary);
      }
    }

    _leaving = false;
  }

  Future<void> _leave() async {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      await _leaveRoom();
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
    List<ChatRoomPresence> presence, {
    ChatRoomMyPermissions? server,
  }) {
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
      room: _effectiveRoom(),
      selfPresence: self,
      server: server ?? ref.read(voiceRoomLiveProvider(_liveRoomKey)).serverPermissions,
    );
  }

  bool _isRoomOwner(String userId, String username, [VoiceRoomEntity? roomIn]) {
    final room = roomIn ?? _effectiveRoom();
    final oid = room.ownerId;
    if (oid != null && oid.isNotEmpty && oid == userId) return true;
    final uname = username.trim().toLowerCase();
    final slug = room.slug.trim().toLowerCase();
    return uname.isNotEmpty && slug == uname;
  }

  Future<void> _shareRoom() async {
    final slug = widget.room.slug;
    final url = '${Env.siteOrigin}/sohbet/$slug';
    final title = widget.room.displayTitle;
    await SharePlus.instance.share(
      ShareParams(
        text: 'CanlıFal sesli odaya katıl: $title\n$url',
        subject: title,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Oda daveti paylaşıldı')),
    );
  }

  Future<void> _openPkInvite(VoiceRoomEntity room) async {
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (key.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oda bilgisi yüklenemedi — PK başlatılamadı')),
      );
      return;
    }
    try {
      await context.push('/voice-room/$key/pk-invite', extra: room);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    }
  }

  void _openActivePk(VoiceRoomEntity room) {
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    context.push('/voice-room/$key/pk', extra: room);
  }

  Future<void> _pickBackground(BuildContext context, VoiceRoomEntity room) async {
    await showVoiceRoomBackgroundSheet(context, ref, room: room);
  }

  List<ChatRoomPresence> _seatedPresence(List<ChatRoomPresence> presence) {
    final seated = presence
        .where((p) => p.seatIndex != null && p.seatIndex! >= 0)
        .toList()
      ..sort((a, b) => (a.seatIndex ?? 99).compareTo(b.seatIndex ?? 99));
    if (seated.isNotEmpty) return seated;
    return presence.where((p) => p.isSpeaking).toList();
  }

  void _openGiftShop(
    BuildContext context, {
    required VoiceRoomEntity room,
    required List<ChatRoomPresence> presence,
    ChatRoomPresence? receiver,
  }) {
    showPremiumVoiceGiftShop(
      context,
      ref,
      room: room,
      seatedUsers: _seatedPresence(presence),
      initialReceiver: receiver,
      onGiftSent: () {
        if (!mounted) return;
        _messageCtrl.clear();
      },
    );
  }

  void _openUser(
    ChatRoomPresence user, {
    VoiceRoomPermissions? perms,
    VoiceRoomEntity? room,
    bool? isOwner,
  }) {
    final auth = ref.read(authControllerProvider).valueOrNull;
    final owner = isOwner ??
        _isRoomOwner(auth?.id ?? '', auth?.username ?? '');
    final liveState = ref.read(voiceRoomLiveProvider(_liveRoomKey));
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
          room: room ?? _effectiveRoom(),
          selfPresence: selfPresence,
          server: liveState.serverPermissions,
        );
    final effectiveRoom = room ?? _effectiveRoom();
    final livePresence = ref.read(voiceRoomLiveProvider(_liveRoomKey)).presence;
    void openGift() => _openGiftShop(
          context,
          room: effectiveRoom,
          presence: livePresence,
          receiver: user,
        );

    if (permissions.canModerate || owner) {
      final djIds = liveState.dj.djUsers.map((u) => u.id).toSet();
      showVoiceRoomModerationSheet(
        context: context,
        ref: ref,
        room: effectiveRoom,
        targetUser: VoiceRoomModerationTarget.fromPresence(user),
        isOwnerOrMod: true,
        perms: permissions,
        isOwner: owner,
        isTargetDj: djIds.contains(user.id),
        onGift: openGift,
      );
      return;
    }
    showVoiceUserProfileSheet(
      context,
      user: user,
      onGift: openGift,
    );
  }

  void _openManagementPanel(
    BuildContext context, {
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
    required VoiceRoomPermissions perms,
    required bool isOwner,
  }) {
    showVoiceRoomManagementPanel(
      context,
      ref,
      room: room,
      live: live,
      perms: perms,
      isOwner: isOwner,
      onUserTap: _openUser,
      onPkInvite: () => unawaited(_openPkInvite(room)),
    );
  }

  void _openHubSettings(
    BuildContext context, {
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
    required VoiceRoomPermissions perms,
    required bool isOwner,
  }) {
    showVoiceRoomManagementPanel(
      context,
      ref,
      room: room,
      live: live,
      perms: perms,
      isOwner: isOwner,
      onUserTap: _openUser,
      onPkInvite: () => unawaited(_openPkInvite(room)),
      initial: VoiceMgmtInitial.chatMgmt,
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
      _openUser(occupant, perms: perms, room: room, isOwner: perms.isRoomOwner);
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
      await _showAssignSeatSheet(
        context,
        room: room,
        live: live,
        seatIndex: internalSeatIndex,
        perms: perms,
      );
      return;
    }
    if (perms.canTakeSeat) {
      final err = await ref
          .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
          .assignSeat(seatIndex: internalSeatIndex);
      if (!context.mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
      return;
    }
  }

  Future<void> _onSeatLongPress(
    BuildContext context, {
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
    required VoiceRoomPermissions perms,
    required int internalSeatIndex,
  }) async {
    if (!perms.canAssignSeats) return;
    await _showAssignSeatSheet(
      context,
      room: room,
      live: live,
      seatIndex: internalSeatIndex,
      perms: perms,
      showAllMembers: true,
    );
  }

  Future<void> _showAssignSeatSheet(
    BuildContext context, {
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
    required int seatIndex,
    required VoiceRoomPermissions perms,
    bool showAllMembers = false,
  }) async {
    final self = ref.read(authControllerProvider).valueOrNull;
    final ctrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
    final onStage = voiceWebOnStageIds(room: room, presence: live.presence);
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
              showAllMembers ? 'Koltuk $seatIndex — kim otursun?' : 'Koltuk $seatIndex',
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
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err)));
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.lock_rounded, color: Colors.amber),
                title: Text(
                  seatSlot?.isLocked == true
                      ? 'Kilidi aç'
                      : 'Koltuğu kilitle',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final err = seatSlot?.isLocked == true
                      ? await ctrl.unlockSeat(seatIndex: seatIndex)
                      : await ctrl.lockSeat(seatIndex: seatIndex);
                  if (context.mounted && err != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
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
                      ? canlifalImageProvider(p.image!)
                      : null,
                  child: p.image == null || p.image!.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(p.displayName),
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
                    : null,
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

  @override
  Widget build(BuildContext context) {
    final roomLookupKey = _liveRoomKey.isNotEmpty
        ? _liveRoomKey
        : (widget.room.apiRoomKey.isNotEmpty ? widget.room.apiRoomKey : widget.room.id);
    final room = _displayRoomFromSingle(
      ref.watch(voiceRoomByIdProvider(roomLookupKey)).valueOrNull,
    );
    ref.watch(
      voiceRoomForegroundLifecycleProvider(
        _liveRoomKey.isNotEmpty ? _liveRoomKey : widget.room.id,
      ),
    );
    ref.watch(
      voiceRoomLiveProvider(_liveRoomKey).select(_RtcLiveShell.fromState),
    );
    final live = ref.read(voiceRoomLiveProvider(_liveRoomKey));
    final roomErrorBanner =
        VoiceRoomErrorDisplay.bannerMessage(live.error, live: live);
    final sessionKey =
        room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    final online = live.onlineCountFor(room);
    final jeton = ref.watch(
      walletBalancesProvider.select((a) => a.valueOrNull?.jeton ?? 0),
    );
    final user = ref.watch(authControllerProvider).valueOrNull;
    final perms = _perms(user, live.presence, server: live.serverPermissions);
    final canSpeak = VoiceRoomSpeakAccess.canSpeak(
      user: user,
      perms: perms,
      room: room,
      presence: live.presence,
    );
    final speakPending = ref.watch(
      voiceRoomUiProvider.select((s) => s.requestSpeakPending),
    );
    final canRequestMusic = VoiceMusicAccess.canRequestSongs(
      dj: live.dj,
      perms: perms,
      jetonBalance: jeton,
    );
    final showMusicRequestFab = live.dj.musicEnabled;
    final audioRequestCost = VoiceMusicAccess.audioRequestCost(live.dj);
    final isOwner = perms.isRoomOwner || perms.isSiteAdmin;
    final isDj = perms.canManageDj ||
        live.dj.canPlayMusic ||
        (user != null && room.djUserIds.contains(user.id)) ||
        live.dj.djUsers.any((u) => user != null && u.id == user.id);
    final canControlMusic = live.dj.canControlMusic ||
        live.dj.canPlayMusic ||
        (user != null && live.dj.nowPlaying?.requestedBy?.id == user.id) ||
        perms.isRoomOwner ||
        perms.isSiteAdmin ||
        isDj;
    final canCloseMusic = VoiceMusicAccess.canStopMusic(
      user: user,
      perms: perms,
      nowPlaying: live.dj.nowPlaying,
    );
    final speakingIds = <String>{
      for (final p in live.presence)
        if (p.isSpeaking) p.id,
    };
    if (!_isMicMuted && user != null) speakingIds.add(user.id);
    final bgUrl = live.backgroundUrl ?? room.backgroundImageUrl;
    final metrics = VoiceRoomResponsiveMetrics.of(context);
    final keyboardOpen = metrics.keyboardOpen;
    final chatMaxH = metrics.chatBlockH;
    final musicDismissed = ref.watch(
      voiceRoomMusicSessionProvider.select(
        (s) => s.dismissed || s.userDismissedPlayer,
      ),
    );
    final hasActiveMusicPlayer = (live.dj.playing ||
            live.dj.nowPlaying != null ||
            live.dj.musicQueue.isNotEmpty) &&
        !musicDismissed;
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
    final mergedDjIds = <String>{
      ...room.djUserIds,
      ...live.dj.djUsers.map((u) => u.id),
    }.toList();
    final headerAvatar = ownerPresence?.image;
    ref.listen<VoiceRoomLiveState>(voiceRoomLiveProvider(_liveRoomKey), (prev, next) {
      if (!mounted) return;

      final exitMsg = VoiceRoomSessionExit.detectExitMessage(prev: prev, next: next);
      if (exitMsg != null && !_forcedExitHandled && !_leaving) {
        _forcedExitHandled = true;
        unawaited(
          VoiceRoomSessionExit.handleForcedExit(
            context: context,
            ref: ref,
            liveKey: _liveRoomKey,
            message: exitMsg,
          ),
        );
        return;
      }

      if (prev?.error != next.error && next.error != null && mounted) {
        final err = next.error!;
        if (err.contains('jeton')) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Yetersiz jeton'),
              content: Text(err),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Kapat'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    openJetonStore(context, ref: ref);
                  },
                  child: const Text('Jeton Yükle'),
                ),
              ],
            ),
          );
          ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).clearError();
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
      if (next.openCommandsPanel && !(prev?.openCommandsPanel ?? false)) {
        ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).clearOpenCommandsPanel();
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

      final q = next.pendingMusicSearchQuery;
      if (q != null &&
          prev?.pendingMusicSearchQuery != q &&
          mounted &&
          !_musicSearchOpen) {
        final skipPayment = next.pendingMusicSearchSkipPayment;
        final ctrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
        final dj = next.dj;
        _musicSearchOpen = true;
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
          ).whenComplete(() => _musicSearchOpen = false),
        );
      }

      final toast = next.moderationToast;
      if (toast != null && toast != prev?.moderationToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(toast),
            duration: const Duration(seconds: 5),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
      final kickWarn = next.kickStrikeWarning;
      if (kickWarn != null && kickWarn != prev?.kickStrikeWarning && mounted) {
        final strikeCount = next.kickStrikeCount.clamp(1, 3);
        final strikeColor = KickStrikeUi.colorFor(strikeCount);
        unawaited(
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1028),
              title: Text(
                KickStrikeUi.titleFor(strikeCount),
                style: TextStyle(
                  color: strikeColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Text(
                kickWarn,
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: strikeColor),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          ),
        );
      }

      final wasPlaying =
          (prev?.dj.playing ?? false) && prev?.dj.nowPlaying != null;
      final nowPlaying = next.dj.playing && next.dj.nowPlaying != null;
      if (!wasPlaying && nowPlaying && !isOwner && _audioReady) {
        if (!_isMicMuted) {
          _audio?.setMicEnabled(false);
          if (mounted) {
            setState(() {
              _isMicMuted = true;
              _micAutoMutedByMusic = true;
            });
          }
        }
      } else if (wasPlaying && !nowPlaying && _micAutoMutedByMusic) {
        final user = ref.read(authControllerProvider).valueOrNull;
        final room = _effectiveRoom();
        final speakPerms = _perms(user, next.presence, server: next.serverPermissions);
        if (VoiceRoomSpeakAccess.canSpeak(
          user: user,
          perms: speakPerms,
          room: room,
          presence: next.presence,
        )) {
          _audio?.setMicEnabled(true);
          if (mounted) {
            setState(() {
              _isMicMuted = false;
              _micAutoMutedByMusic = false;
            });
          }
        } else if (mounted) {
          setState(() => _micAutoMutedByMusic = false);
        }
      }

      if (_audioReady) {
        final user = ref.read(authControllerProvider).valueOrNull;
        if (user != null) {
          final room = _effectiveRoom();
          final speakPerms =
              _perms(user, next.presence, server: next.serverPermissions);
          final canSpeak = VoiceRoomSpeakAccess.canSpeak(
            user: user,
            perms: speakPerms,
            room: room,
            presence: next.presence,
          );
          if (!canSpeak && !_isMicMuted) {
            _audio?.setMicEnabled(false);
            if (mounted) setState(() => _isMicMuted = true);
          } else {
            ChatRoomPresence? selfPresence;
            for (final p in next.presence) {
              if (p.id == user.id) {
                selfPresence = p;
                break;
              }
            }
            final seat = selfPresence?.seatIndex;
            if (canSpeak &&
                seat != null &&
                seat >= 0 &&
                seat != _lastSelfSeatIndex &&
                _isMicMuted) {
              _audio?.setMicEnabled(true);
              if (mounted) setState(() => _isMicMuted = false);
            }
            _lastSelfSeatIndex = seat;
          }
        }
      }
    });

    ref.listen(voiceRoomUiProvider, (prev, next) {
      if (prev?.backgroundMusicEnabled != next.backgroundMusicEnabled) {
        unawaited(
          ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).refresh(includeDj: true),
        );
      }
      if (prev?.headphonesOn != next.headphonesOn && _audioReady) {
        _audio?.setHeadphonesOn(next.headphonesOn);
      }
    });

    ref.listen(authControllerProvider, (prev, next) {
      final wasGuest = prev?.valueOrNull == null;
      final nowUser = next.valueOrNull;
      if (wasGuest && nowUser != null && _loginError != null && !_audioReady) {
        unawaited(_joinAudioBackground());
      }
    });

    ref.listen(voiceRoomsProvider, (prev, next) {
      final synced = _roomSynced(next.valueOrNull);
      if (synced.apiRoomKey.isEmpty) return;
      final hadKey = _roomSynced(prev?.valueOrNull).apiRoomKey.isNotEmpty;
      if (!hadKey && !_audioReady && !_leaving) {
        unawaited(_joinAudioBackground());
      }
    });

    return GiftEventListener(
      sessionKey: sessionKey,
      isHost: isOwner,
      child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leaveRoom();
      },
      child: Scaffold(
        backgroundColor: VoiceRoomTokens.bgDeep,
        resizeToAvoidBottomInset: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            VoiceCosmicBackground(imageUrl: bgUrl),
            if (_liveRoomKey.isNotEmpty) ...[
              VoiceRoomMusicBackgroundLayer(roomKey: _liveRoomKey),
              VoiceRoomHiddenAudioPlayer(roomKey: _liveRoomKey),
            ],
            Consumer(
              builder: (context, ref, _) {
                final activeGift = ref.watch(
                  giftSessionProvider(sessionKey).select((s) => s.activeAnimation),
                );
                final giftsOn = ref.watch(
                  voiceRoomUiProvider.select((s) => s.giftAnimationsEnabled),
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: GiftEngineOverlay(
                          event: activeGift,
                          enabled: giftsOn,
                          stage: GiftStageContext.voiceRoom,
                          sessionKey: sessionKey,
                          onFinished: (id) {
                            ref
                                .read(giftSessionProvider(sessionKey).notifier)
                                .dequeueAnimation(id);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            Column(
              children: [
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        if (room.apiRoomKey.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: VoiceRoomTokens.neonPurple,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Oda bilgisi yükleniyor…',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_loginError != null)
                          Material(
                            color: AppThemeColors.liveRed.withValues(alpha: 0.18),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.login_rounded,
                                color: AppThemeColors.liveRed,
                                size: 20,
                              ),
                              title: Text(
                                _loginError!,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: TextButton(
                                onPressed: () => context.push('/login'),
                                child: const Text('Giriş yap'),
                              ),
                            ),
                          ),
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
                                onPressed: _joinAudioBackground,
                                child: const Text('Tekrar'),
                              ),
                            ),
                          ),
                        VoiceWebRoomHeader(
                          room: room,
                          onlineCount: online,
                          coinBalance: jeton,
                          onCoinsTap: () => openJetonStore(context, ref: ref),
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
                          onSettings: () => _openManagementPanel(
                            context,
                            room: room,
                            live: live,
                            perms: perms,
                            isOwner: isOwner,
                          ),
                          onRoomPanel: () => showVoiceSpeakerListSheet(
                            context,
                            presence: live.presence,
                            room: room,
                            onUserTap: _openUser,
                          ),
                          onShare: _shareRoom,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Sesli oda: video müzik katmanı yok — yalnızca just_audio.
                              LayoutBuilder(
                                  builder: (context, constraints) {
                                    final chatH = keyboardOpen
                                        ? chatMaxH
                                        : constraints.maxHeight;
                                    return Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                        if (live.loading && live.presence.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: VoiceRoomTokens.neonPurple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Katılımcılar yükleniyor…',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (roomErrorBanner != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              roomErrorBanner,
                              style: const TextStyle(
                                color: AppThemeColors.liveRed,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const _VoiceRoomRtcDiagnosticBanner(),
                        VoiceWebOwnerStage(
                              room: room,
                              presence: live.presence,
                              seatSlots: live.seatSlots,
                              djUserIds: mergedDjIds,
                              speakingUserIds: speakingIds,
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
                              onSeatLongPress: (seatIndex) => unawaited(
                                _onSeatLongPress(
                                  context,
                                  room: room,
                                  live: live,
                                  perms: perms,
                                  internalSeatIndex: seatIndex,
                                ),
                              ),
                              trtc: _audio?.trtcManager,
                              trtcReady: _audioReady,
                              selfUserId: user?.id,
                              remoteTrtcUserId:
                                  _audio?.trtcManager.remoteAnchorUserId,
                            ),
                        VoiceRoomCenterMusicPanel(
                          room: room,
                          live: live,
                          canControlMusic: canControlMusic,
                          canCloseMusic: canCloseMusic,
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final banner = ref.watch(
                              voiceRoomLiveProvider(_liveRoomKey).select(
                                (s) => s.enterBanner,
                              ),
                            );
                            return VoiceRoomStaffJoinBanner(
                              enterBanner: banner,
                            );
                          },
                        ),
                        VoicePkInviteBanner(
                          room: room,
                          liveKey: _liveRoomKey,
                          isOwner: isOwner,
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final ann = ref.watch(
                              voiceRoomLiveProvider(_liveRoomKey).select(
                                (s) => s.moderatorAnnouncement,
                              ),
                            );
                            if (ann?.trim().isNotEmpty != true) {
                              return const SizedBox.shrink();
                            }
                            return VoiceRoomDuyuruTicker(
                              key: ValueKey(ann),
                              text: ann!,
                              onScrollComplete: () => ref
                                  .read(
                                    voiceRoomLiveProvider(_liveRoomKey).notifier,
                                  )
                                  .clearModeratorAnnouncement(),
                            );
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: VoiceGiftAnnouncementTicker(),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: LuckyGiftWinsTicker(),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GiftBattleStrip(
                            context: 'voice_room',
                            contextId: room.apiRoomKey.isNotEmpty
                                ? room.apiRoomKey
                                : room.id,
                          ),
                        ),
                        if (!keyboardOpen && !hasActiveMusicPlayer)
                          VoiceRoomPersistentDuyuru(
                            roomKey: room.apiRoomKey.isNotEmpty
                                ? room.apiRoomKey
                                : room.id,
                            text: duyuru,
                            canEdit: perms.canModerate || isOwner,
                            onEdit: (perms.canModerate || isOwner)
                                ? () => _openHubSettings(
                                      context,
                                      room: room,
                                      live: live,
                                      perms: perms,
                                      isOwner: isOwner,
                                    )
                                : null,
                          ),
                        Expanded(
                          child: RepaintBoundary(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final chat = ref.watch(
                                  voiceRoomLiveProvider(_liveRoomKey).select(
                                    (s) => (
                                      messages: s.messages,
                                      pinned: s.pinnedAnnouncement,
                                      typing: s.isAnyoneTyping,
                                      typingUsers: s.typingUsers,
                                    ),
                                  ),
                                );
                                return Column(
                                  children: [
                                    Expanded(
                                      child: VoiceWebChatOverlay(
                                        messages: chat.messages,
                                        hideOfficialJoinInChat: false,
                                        maxHeight: chatH,
                                        embedded: true,
                                        welcomeMarquee: null,
                                        roomName: room.nameTr,
                                        pinnedAnnouncement: chat.pinned,
                                        scrollController: _chatScrollCtrl,
                                        scrollToLatest: _scrollChatToLatest,
                                        onUserTap: (id, name, msg) =>
                                            _openUserFromChat(
                                          id,
                                          name,
                                          msg,
                                          room: room,
                                          live: ref.read(
                                            voiceRoomLiveProvider(_liveRoomKey),
                                          ),
                                          perms: perms,
                                          isOwner: isOwner,
                                        ),
                                      ),
                                    ),
                                    if (chat.typing)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          0,
                                          12,
                                          4,
                                        ),
                                        child: Text(
                                          '${chat.typingUsers.join(', ')} yazıyor…',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white.withValues(
                                              alpha: 0.65,
                                            ),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                                      ],
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                              if (!keyboardOpen)
                                VoiceRoomBottomDock(
                                  room: room,
                                  session: room,
                                  live: live,
                                  canControlMusic: canControlMusic,
                                  canStopMusic: canCloseMusic,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final footerLive = ref.watch(
                      voiceRoomLiveProvider(_liveRoomKey).select(
                        (s) => (s.messages, s.realtimeEvents, s.presence),
                      ),
                    );
                    final headphonesOn = ref.watch(
                      voiceRoomUiProvider.select((s) => s.headphonesOn),
                    );
                    final joinNotificationsEnabled = ref.watch(
                      voiceRoomUiProvider
                          .select((s) => s.chatNotificationSoundEnabled),
                    );
                    return VoiceRoomSpecFooter(
                      controller: _messageCtrl,
                      focusNode: _messageFocus,
                      onSend: () => _sendChatMessage(room),
                      onToggleAudioOutput: _toggleHeadphones,
                      headphonesOn: headphonesOn,
                      onMicToggle: _toggleMic,
                      micOn: !_isMicMuted,
                      micEnabled: _audioReady,
                      onSettings: () => _openManagementPanel(
                        context,
                        room: room,
                        live: ref.read(voiceRoomLiveProvider(_liveRoomKey)),
                        perms: perms,
                        isOwner: isOwner,
                      ),
                      onGift: () => _openGiftShop(
                        context,
                        room: room,
                        presence: footerLive.$3,
                      ),
                      onInvite: () => unawaited(_shareRoom()),
                      presence: footerLive.$3,
                      selfUserId: user?.id,
                      events: footerLive.$2,
                      messages: footerLive.$1,
                      onEmojiTap: () => _showEmojiPicker(context, _messageCtrl),
                      onChanged: _onChatChanged,
                      joinNotificationsEnabled: joinNotificationsEnabled,
                      showMusicRequest: showMusicRequestFab,
                      showSpeakRequest: user != null && !canSpeak,
                      speakRequestPending: speakPending,
                      onSpeakRequest: () => unawaited(
                        requestVoiceRoomBasicSpeak(
                          context: context,
                          ref: ref,
                          liveKey: _liveRoomKey,
                          pending: speakPending,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            VoiceGiftHudOverlays(
              sessionKey: sessionKey,
              seatEffectBound: voiceRoomGiftSeatEffectBound(
                room: room,
                seatSlots: live.seatSlots,
                configuredSeatCount: live.roomSeatCount ?? room.seatCount,
              ),
            ),
            if (!keyboardOpen && showMusicRequestFab)
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 118),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      VoiceRoomMusicQueueMiniCard(
                        dj: live.dj,
                        liveKey: _liveRoomKey,
                        canControlMusic: canControlMusic,
                        canStopMusic: canCloseMusic,
                      ),
                      const SizedBox(height: 8),
                      VoiceRoomMusicRequestFab(
                        enabled: showMusicRequestFab,
                        active: canRequestMusic,
                        audioCost: audioRequestCost,
                        onPressed: () => showVoiceYoutubeSongSheet(
                          context,
                          ref,
                          room: room,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_liveRoomKey.isNotEmpty)
              BlocProvider.value(
                value: ref.read(roomSongBlocProvider(_liveRoomKey)),
                child: _VoiceRoomRtcSongMiniPlayer(
                  roomId: _liveRoomKey,
                  canControl: canControlMusic,
                  bottomInset: 118,
                ),
              ),
            if (_showVipEntrance && user != null)
              _VoiceRoomRtcVipEntrance(
                user: user,
                onFinished: () {
                  if (mounted) setState(() => _showVipEntrance = false);
                },
              ),
            // Sesli sohbet prompt: sağ kayar DJ paneli kaldırıldı; müzik !istek + komutlar.
          ],
        ),
      ),
    ),
    );
  }
}

/// Teşhis kartı — yalnızca hata varken provider dinler.
class _VoiceRoomRtcDiagnosticBanner extends ConsumerWidget {
  const _VoiceRoomRtcDiagnosticBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostic = ref.watch(voiceRoomDiagnosticProvider);
    if (diagnostic.uiBuildError == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: VoiceRoomDiagnosticCard(state: diagnostic),
    );
  }
}

/// Müzik mini oynatıcı — Bloc + mute durumu izole.
class _VoiceRoomRtcSongMiniPlayer extends ConsumerWidget {
  const _VoiceRoomRtcSongMiniPlayer({
    required this.roomId,
    required this.canControl,
    required this.bottomInset,
  });

  final String roomId;
  final bool canControl;
  final double bottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = ref.watch(
      voiceRoomUiProvider.select((s) => s.effectiveMusicMuted),
    );
    return RoomSongMiniPlayer(
      roomId: roomId,
      canControl: canControl,
      bottomInset: bottomInset,
      muted: muted,
      hidden: true,
    );
  }
}

/// VIP giriş animasyonu — kozmetik/tier provider'ları izole.
class _VoiceRoomRtcVipEntrance extends ConsumerWidget {
  const _VoiceRoomRtcVipEntrance({
    required this.user,
    required this.onFinished,
  });

  final UserEntity user;
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : user.username;
    final cosmetic = ref.watch(resolvedEntranceEffectProvider);
    if (cosmetic != null) {
      return CosmeticEntranceOverlay(
        userName: name,
        effectKind: cosmetic.effectKind,
        onFinished: onFinished,
      );
    }
    return VipEntranceOverlay(
      tier: ref.watch(vipTierProvider),
      theme: ref.watch(myEntranceThemeProvider),
      userName: name,
      onFinished: onFinished,
    );
  }
}

/// Yeni sohbet mesajı geldiğinde koltuk/arka plan yeniden çizilmez.
@immutable
class _RtcLiveShell {
  const _RtcLiveShell({
    required this.presence,
    required this.dj,
    required this.serverPermissions,
    required this.backgroundUrl,
    required this.loading,
    required this.error,
    required this.enterBanner,
    required this.realtimeEvents,
  });

  factory _RtcLiveShell.fromState(VoiceRoomLiveState s) => _RtcLiveShell(
        presence: s.presence,
        dj: s.dj,
        serverPermissions: s.serverPermissions,
        backgroundUrl: s.backgroundUrl,
        loading: s.loading,
        error: s.error,
        enterBanner: s.enterBanner,
        realtimeEvents: s.realtimeEvents,
      );

  final List<ChatRoomPresence> presence;
  final ChatRoomDjState dj;
  final ChatRoomMyPermissions? serverPermissions;
  final String? backgroundUrl;
  final bool loading;
  final String? error;
  final String? enterBanner;
  final List<VoiceRoomRealtimeEvent> realtimeEvents;

  @override
  bool operator ==(Object other) =>
      other is _RtcLiveShell &&
      identical(presence, other.presence) &&
      dj == other.dj &&
      serverPermissions == other.serverPermissions &&
      backgroundUrl == other.backgroundUrl &&
      loading == other.loading &&
      error == other.error &&
      enterBanner == other.enterBanner &&
      identical(realtimeEvents, other.realtimeEvents);

  @override
  int get hashCode => Object.hash(
        presence,
        dj,
        serverPermissions,
        backgroundUrl,
        loading,
        error,
        enterBanner,
        realtimeEvents,
      );
}
