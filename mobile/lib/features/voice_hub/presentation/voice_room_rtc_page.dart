import 'dart:async';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/performance/voice_room_entry_perf.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/widgets/cached_cover_image.dart';
import '../../../core/navigation/wallet_navigation.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../live/domain/entities/live_gift_event.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/presentation/providers/live_providers.dart';
import '../data/services/voice_room_debug_log.dart';
import '../domain/voice_official_join.dart';
import '../../gifts/domain/premium_gift_catalog_2026.dart';
import '../../gifts/presentation/widgets/premium_2026/premium_gift_fullscreen_overlay.dart';
import 'providers/voice_gift_combo_tracker.dart';
import 'providers/voice_gift_leaderboard_provider.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../agora/presentation/agora_room_manager.dart';
import '../../agora/presentation/providers/agora_providers.dart';
import '../domain/entities/chat_room_message.dart';
import '../domain/entities/chat_room_presence.dart';
import '../domain/entities/chat_room_sse_event.dart';
import '../domain/entities/chat_room_my_permissions.dart';
import 'audio/voice_room_audio_coordinator.dart';
import 'audio/voice_room_music_audio_session.dart';
import 'providers/chat_room_providers.dart';
import '../music/presentation/widgets/music_search_picker_sheet.dart';
import 'sheets/voice_room_hub_settings.dart';
import 'providers/pk_battle_remote_provider.dart';
import '../domain/pk/pk_duration_options.dart';
import 'utils/voice_room_image_prefetch.dart';
import 'providers/voice_gift_providers.dart';
import 'providers/voice_room_audio_providers.dart';
import 'providers/voice_room_diagnostic_provider.dart';
import 'providers/voice_room_sse_provider.dart';
import 'providers/voice_room_ui_provider.dart';
import '../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../vip_gold/presentation/widgets/vip_entrance_overlay.dart';
import 'sheets/voice_room_speak_queue_sheet.dart';
import 'sheets/voice_room_menu_sheet.dart';
import 'sheets/voice_room_moderation_sheet.dart';
import 'sheets/voice_room_sheets.dart';
import 'utils/voice_music_access.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import 'theme/voice_room_tokens.dart';
import 'utils/voice_room_permissions.dart';
import 'utils/voice_room_speak_access.dart';
import 'utils/voice_room_responsive_metrics.dart';
import 'widgets/premium/voice_gift_flight_overlay.dart';
import 'widgets/premium/voice_glass.dart';
import 'widgets/premium_2026/voice_cosmic_background.dart';
import 'widgets/voice_room/voice_room_spec_footer.dart';
import 'sheets/voice_room_commands_panel.dart';
import 'sheets/voice_youtube_song_sheet.dart';
import 'widgets/premium_2026/voice_room_persistent_duyuru.dart';
import 'widgets/voice_room/voice_room_duyuru_ticker.dart';
import 'utils/kick_strike_ui.dart';
import 'widgets/premium_2026/voice_web_chat_overlay.dart';
import 'widgets/premium_2026/voice_web_owner_stage.dart';
import 'widgets/premium_2026/voice_web_room_header.dart';
import 'widgets/voice_room/voice_dj_music_slide_panel.dart';
import 'widgets/voice_room/voice_room_seat_video_strip.dart';
import 'widgets/voice_room/voice_room_staff_join_banner.dart';
import 'widgets/voice_room/voice_room_bottom_dock.dart';
import 'widgets/voice_room_error_boundary.dart';
import '../video/presentation/widgets/room_video_overlay.dart';
import '../video/presentation/room_video_controller.dart';

/// Sesli sohbet odası — Agora (App ID only) + canlifal.com chat API.
class VoiceRoomRtcPage extends ConsumerStatefulWidget {
  const VoiceRoomRtcPage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<VoiceRoomRtcPage> createState() => _VoiceRoomRtcPageState();
}

class _VoiceRoomRtcPageState extends ConsumerState<VoiceRoomRtcPage> {
  VoiceRoomAudioCoordinator? _audio;
  final _agora = AgoraRoomManager();
  StreamSubscription<LiveGiftEvent>? _giftSub;
  StreamSubscription<ChatRoomSseEvent>? _sseParticipantsSub;
  var _participants = <String, Map<String, dynamic>>{};
  var _agoraReady = false;
  final _messageCtrl = TextEditingController();
  final _chatScrollCtrl = ScrollController();
  var _scrollChatToLatest = false;
  var _audioJoining = false;
  var _audioReady = false;
  String? _audioError;
  String? _loginError;
  var _isMicMuted = false;
  var _micAutoMutedByMusic = false;
  var _leaving = false;
  LiveGiftEvent? _fullscreenGift;
  var _showVipEntrance = false;
  var _vipEntrancePlayed = false;
  String? _shownPkInviteId;
  final _messageFocus = FocusNode();
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
      _startGiftRealtime();
      unawaited(_joinAudioBackground());
      _prefetchRoomImages();
      _bindSseParticipants();
    });
  }

  void _bindSseParticipants() {
    _sseParticipantsSub?.cancel();
    _sseParticipantsSub =
        ref.read(voiceRoomSseForProvider(_liveRoomKey)).events.listen((event) {
      if (!mounted) return;
      if (event.type == ChatRoomSseEventType.presence) {
        final raw = event.data['users'] ?? event.data['presence'];
        if (raw is! List) return;
        final users = List<Map<String, dynamic>>.from(
          raw.whereType<Map>().map((u) => Map<String, dynamic>.from(u)),
        );
        if (!mounted) return;
        setState(() {
          _participants = {
            for (final u in users)
              (u['id']?.toString() ?? ''): u,
          }..removeWhere((key, _) => key.isEmpty);
        });
      }
    });
  }

  Future<void> _joinAgoraVideo({
    required VoiceRoomEntity room,
    required UserEntity user,
    required bool publishVideo,
  }) async {
    if (!_agora.isSupported) return;
    try {
      final cred = await ref.read(agoraRemoteProvider).fetchVoiceRoomToken(
            roomId: room.apiRoomKey,
            role: publishVideo ? 'host' : 'audience',
          );
      await _agora.joinVoiceRoomVideo(
        credentials: cred,
        publishVideo: publishVideo,
      );
      if (mounted) setState(() => _agoraReady = true);
      VoiceRoomDebugLog.log('agora.voice_room.joined', {
        'channel': cred.channelName,
        'publishVideo': publishVideo,
      });
    } catch (e) {
      VoiceRoomDebugLog.log('agora.voice_room.fail', {'error': '$e'});
    }
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

  VoiceRoomEntity _effectiveRoom() {
    return _displayRoom(ref.read(voiceRoomsProvider).valueOrNull);
  }

  @override
  void dispose() {
    _giftSub?.cancel();
    _giftSub = null;
    _sseParticipantsSub?.cancel();
    _sseParticipantsSub = null;
    _participants.clear();
    _messageCtrl.dispose();
    _chatScrollCtrl.dispose();
    _messageFocus.dispose();
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
    unawaited(_agora.dispose());
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

  void _toggleMic() {
    if (_audio == null || !_audioReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses bağlantısı hazır değil')),
      );
      return;
    }
    final muted = !_isMicMuted;
    if (!muted) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Konuşmak için koltuğa oturmalısınız'),
          ),
        );
        return;
      }
    }
    _audio?.setMicEnabled(!muted);
    if (mounted) setState(() => _isMicMuted = muted);
  }

  void _onChatChanged(String text) {
    ref
        .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
        .notifyTyping(text.trim().isNotEmpty);
  }

  void _toggleHeadphones() {
    ref.read(voiceRoomUiProvider.notifier).toggleHeadphones();
    _audio?.setHeadphonesOn(ref.read(voiceRoomUiProvider).headphonesOn);
  }

  void _startGiftRealtime() {
    final service = ref.read(voiceRoomGiftRealtimeProvider);
    final room = _effectiveRoom();
    final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    if (key.isEmpty) return;
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
      final rarity = PremiumGiftCatalog2026.rarity(event.giftId);
      final duration = rarity.fullscreenDuration;
      if (mounted) setState(() => _fullscreenGift = event);
      Future.delayed(duration, () {
        if (mounted && _fullscreenGift?.id == event.id) {
          setState(() => _fullscreenGift = null);
        }
      });
    }
  }

  Future<UserEntity?> _waitForAuth({Duration timeout = const Duration(seconds: 12)}) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isLoading) return auth.valueOrNull;
    try {
      return await ref.read(authControllerProvider.future).timeout(timeout);
    } catch (_) {
      return ref.read(authControllerProvider).valueOrNull;
    }
  }

  Future<void> _joinAudioBackground() async {
    if (!mounted) return;
    setState(() {
      _audioJoining = true;
      _audioError = null;
    });

    final user = await _waitForAuth(timeout: VoiceRoomEntryPerf.entryBudget);
    if (!mounted) return;
    if (user == null) {
      setState(() {
        _audioJoining = false;
        _loginError = 'Odaya girmek için giriş yapın';
      });
      return;
    }

    setState(() => _loginError = null);

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
            .timeout(const Duration(seconds: 15));
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
      return;
    }

    _startGiftRealtime();
    unawaited(_connectPkBattle());

    _audio = ref.read(voiceRoomAudioCoordinatorProvider);
    if (!_audio!.isSupported) {
      if (mounted) {
        setState(() {
          _audioJoining = false;
          _audioError = 'Ses bağlantısı bu cihazda desteklenmiyor; sohbet çalışır';
        });
      }
      _startGiftRealtime();
      _maybeShowVipEntrance(user);
      unawaited(_connectPkBattle());
      return;
    }

    try {
      final liveForPerms = ref.read(voiceRoomLiveProvider(_liveRoomKey));
      ChatRoomPresence? selfPresence;
      for (final p in liveForPerms.presence) {
        if (p.id == user.id) {
          selfPresence = p;
          break;
        }
      }
      final perms = VoiceRoomPermissions.forUser(
        user: user,
        room: room,
        selfPresence: selfPresence,
        server: liveForPerms.serverPermissions,
      );
      final canSpeak = VoiceRoomSpeakAccess.canSpeak(
        user: user,
        perms: perms,
        room: room,
        presence: liveForPerms.presence,
      );
      final roomId = room.apiRoomKey;
      await _audio!.join(
        roomId: roomId,
        remote: ref.read(chatRoomRemoteProvider),
        enableMic: false,
      );
      if (mounted) {
        ref.read(voiceRoomDiagnosticProvider.notifier).setTrtc(
              roomId: roomId,
              result: 1,
            );
        ref.read(voiceRoomDiagnosticProvider.notifier).setAudioReady(true);
        unawaited(VoiceRoomMusicAudioSession.activateForPlayback());
        setState(() {
          _audioJoining = false;
          _audioReady = true;
          _isMicMuted = !_audio!.micOn;
        });
        _startGiftRealtime();
        ref.read(voiceRoomDiagnosticProvider.notifier).setSocket(true);
        _audio?.setHeadphonesOn(ref.read(voiceRoomUiProvider).headphonesOn);
        _maybeShowVipEntrance(user);
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
        _maybeShowVipEntrance(user);
        unawaited(_connectPkBattle());
      }
    } finally {
      if (mounted && _audioJoining) {
        setState(() => _audioJoining = false);
      }
    }
  }

  Future<void> _connectPkBattle() async {
    if (!mounted) return;
    final r = _effectiveRoom();
    final roomKey = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
    if (roomKey.isEmpty) return;
    final remote = ref.read(pkBattleRemoteProvider.notifier);
    await remote.loadRoomBattle(
      roomKey,
      alternateRoomId: r.slug != roomKey ? r.slug : null,
    );
    if (!mounted) return;
    final battle = ref.read(pkBattleRemoteProvider);
    if (battle == null || battle.isEnded) {
      if (battle != null && battle.isEnded) remote.clear();
      return;
    }
    remote.connectSocket(
      roomId: roomKey,
      alternateRoomId: r.slug != roomKey ? r.slug : null,
      battleId: battle.id,
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
    _giftSub?.cancel();
    _giftSub = null;

    final liveCtrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
    final audio = _audio;
    _audio = null;
    unawaited(_agora.leave());
    if (mounted) setState(() => _agoraReady = false);

    // Oturumu ve ses motorunu arka planda kapat — UI donmasın.
    unawaited(liveCtrl.leaveRoomSession(source: 'rtc_leave'));
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
    await Share.share(
      'CanlıFal sesli odaya katıl: $title\n$url',
      subject: title,
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

  Future<void> _showIncomingPkInvite(String battleId) async {
    if (!mounted) return;
    final battle = ref.read(pkBattleRemoteProvider);
    final durationLabel = battle != null
        ? pkDurationBySeconds(battle.durationSeconds).label
        : '3 dakika';
    final accept = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0F2E),
        title: const Text('PK Daveti', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bir oda size PK daveti gönderdi.\nSüre: $durationLabel\n\nKabul ediyor musunuz?',
          style: const TextStyle(color: Colors.white70),
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
    final r = widget.room;
    final roomKey = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
    final altRoom = r.slug != roomKey ? r.slug : null;
    if (accept == true) {
      await remote.accept(
        battleId,
        roomId: roomKey,
        alternateRoomId: altRoom,
      );
      if (mounted) _openActivePk(widget.room);
    } else if (accept == false) {
      await remote.reject(
        battleId,
        roomId: roomKey,
        alternateRoomId: altRoom,
      );
    }
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

  void _openHubSettings(
    BuildContext context, {
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
    required VoiceRoomPermissions perms,
    required bool isOwner,
  }) {
    showVoiceRoomMenuSheet(
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
    required VoiceRoomPermissions perms,
  }) async {
    final self = ref.read(authControllerProvider).valueOrNull;
    final ctrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
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

  Future<void> _requestSpeakFromSeat(
    BuildContext context,
    VoiceRoomEntity room,
    VoiceRoomUiState ui,
  ) async {
    final liveCtrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
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
        final ctrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
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
    final room = _displayRoom(ref.watch(voiceRoomsProvider).valueOrNull);
    ref.watch(
      voiceRoomForegroundLifecycleProvider(
        _liveRoomKey.isNotEmpty ? _liveRoomKey : widget.room.id,
      ),
    );
    final live = ref.watch(voiceRoomLiveProvider(_liveRoomKey));
    final diagnostic = ref.watch(voiceRoomDiagnosticProvider);
    final ui = ref.watch(voiceRoomUiProvider);
    final flightQueue = ref.watch(voiceGiftFlightQueueProvider);
    final online = live.onlineCountFor(room);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final perms = _perms(user, live.presence, server: live.serverPermissions);
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
    final videoState = ref.watch(roomVideoControllerProvider(_liveRoomKey));
    final videoActive = videoState.hasActiveVideo;
    final speakingIds = <String>{
      for (final p in live.presence)
        if (p.isSpeaking) p.id,
    };
    if (!_isMicMuted && user != null) speakingIds.add(user.id);
    final bgUrl = live.backgroundUrl ?? room.backgroundImageUrl;
    final metrics = VoiceRoomResponsiveMetrics.of(context);
    final keyboardOpen = metrics.keyboardOpen;
    final chatMaxH = metrics.chatBlockH;
    final musicSession = ref.watch(voiceRoomMusicSessionProvider);
    final hasActiveMusicPlayer = (live.dj.playing ||
            live.dj.nowPlaying != null ||
            live.dj.musicQueue.isNotEmpty) &&
        !musicSession.dismissed &&
        !musicSession.userDismissedPlayer;
    final showDjSlidePanel = VoiceMusicAccess.canShowDjMusicPanel(
      perms: perms,
      isDj: isDj,
    );
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
          mounted) {
        final skipPayment = next.pendingMusicSearchSkipPayment;
        final ctrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
        ctrl.clearPendingMusicSearch();
        unawaited(
          showMusicSearchPickerSheet(
            context,
            ref,
            query: q,
            onSelected: (hit) async {
              if (!mounted) return;
              final err = await ctrl.submitSelectedSong(
                hit,
                withVideo: true,
                skipPayment: skipPayment,
              );
              if (!mounted || err == null) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(err)),
              );
            },
          ),
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
          }
        }
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

    return PopScope(
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
                          onRoomPanel: perms.canAssignSeats
                              ? () => showVoiceSpeakQueueSheet(
                                    context,
                                    ref,
                                    room: room,
                                    live: live,
                                    perms: perms,
                                  )
                              : () => showVoiceSpeakerListSheet(
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
                        if (diagnostic.uiBuildError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: VoiceRoomDiagnosticCard(state: diagnostic),
                          ),
                        VoiceWebOwnerStage(
                          room: room,
                          presence: live.presence,
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
                          agora: _agora,
                          agoraReady: _agoraReady,
                          selfUserId: user?.id,
                          remoteAgoraUid: _agora.remoteUid,
                        ),
                        VoiceRoomStaffJoinBanner(
                          enterBanner: live.enterBanner,
                        ),
                        if (live.moderatorAnnouncement?.trim().isNotEmpty == true)
                          VoiceRoomDuyuruTicker(
                            key: ValueKey(live.moderatorAnnouncement),
                            text: live.moderatorAnnouncement!,
                            onScrollComplete: () => ref
                                .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
                                .clearModeratorAnnouncement(),
                          ),
                        VoiceRoomSeatVideoStrip(roomKey: _liveRoomKey),
                        RoomVideoOverlay(
                          roomKey: _liveRoomKey,
                          perms: perms,
                          isDj: isDj,
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
                            child: VoiceWebChatOverlay(
                              messages: live.messages,
                              hideOfficialJoinInChat: true,
                              maxHeight: chatH,
                              embedded: true,
                              welcomeMarquee: null,
                              roomName: room.nameTr,
                              pinnedAnnouncement: live.pinnedAnnouncement,
                              scrollController: _chatScrollCtrl,
                              scrollToLatest: _scrollChatToLatest,
                              onUserTap: (id, name, msg) => _openUserFromChat(
                                id,
                                name,
                                msg,
                                room: room,
                                live: live,
                                perms: perms,
                                isOwner: isOwner,
                              ),
                            ),
                          ),
                        ),
                        if (live.isAnyoneTyping)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                            child: Text(
                              '${live.typingUsers.join(', ')} yazıyor…',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.65),
                                fontStyle: FontStyle.italic,
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
                VoiceRoomSpecFooter(
                  controller: _messageCtrl,
                  focusNode: _messageFocus,
                  onSend: () => _sendChatMessage(room),
                  onToggleAudioOutput: _toggleHeadphones,
                  headphonesOn: ui.headphonesOn,
                  onMicToggle: _toggleMic,
                  micOn: !_isMicMuted,
                  micEnabled: _audioReady,
                  onMusicRequest: () => showVoiceYoutubeSongSheet(
                    context,
                    ref,
                    room: room,
                  ),
                  onMusicAudio: () => showVoiceYoutubeSongSheet(
                    context,
                    ref,
                    room: room,
                    preferVideo: false,
                  ),
                  onMusicVideo: () => showVoiceYoutubeSongSheet(
                    context,
                    ref,
                    room: room,
                    preferVideo: true,
                  ),
                  onGift: () => _openGiftShop(
                    context,
                    room: room,
                    presence: live.presence,
                  ),
                  onInvite: () => unawaited(_shareRoom()),
                  presence: live.presence,
                  selfUserId: user?.id,
                  events: live.realtimeEvents,
                  messages: live.messages,
                  onEmojiTap: () => _showEmojiPicker(context, _messageCtrl),
                  onChanged: _onChatChanged,
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
            if (!keyboardOpen)
              VoiceDjMusicSlidePanel(
                room: room,
                live: live,
                perms: perms,
                isOwner: isOwner,
                isDj: isDj,
              ),
          ],
        ),
      ),
    );
  }
}
