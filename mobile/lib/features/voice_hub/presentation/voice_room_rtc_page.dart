import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
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
import '../domain/entities/chat_room_presence.dart';
import '../domain/entities/chat_room_my_permissions.dart';
import '../../trtc/presentation/providers/trtc_providers.dart';
import 'audio/voice_room_audio_coordinator.dart';
import 'providers/chat_room_providers.dart';
import '../music/presentation/widgets/music_search_picker_sheet.dart';
import 'providers/pk_battle_remote_provider.dart';
import '../domain/pk/pk_duration_options.dart';
import 'utils/voice_room_image_prefetch.dart';
import 'providers/voice_gift_providers.dart';
import 'providers/voice_room_audio_providers.dart';
import 'providers/voice_room_diagnostic_provider.dart';
import 'providers/voice_room_ui_provider.dart';
import '../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../vip_gold/presentation/widgets/vip_entrance_overlay.dart';
import 'sheets/voice_room_speak_queue_sheet.dart';
import 'sheets/voice_room_hub_settings.dart';
import 'sheets/voice_room_moderation_sheet.dart';
import 'sheets/voice_room_sheets.dart';
import 'utils/voice_music_access.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import 'theme/voice_room_tokens.dart';
import 'utils/voice_room_permissions.dart';
import 'utils/voice_room_responsive_metrics.dart';
import 'widgets/premium/voice_gift_flight_overlay.dart';
import 'widgets/premium/voice_glass.dart';
import 'widgets/premium_2026/voice_cosmic_background.dart';
import 'widgets/voice_room/voice_room_spec_footer.dart';
import 'sheets/voice_room_commands_panel.dart';
import 'sheets/music_mode_picker_sheet.dart';
import 'widgets/premium_2026/voice_room_persistent_duyuru.dart';
import 'widgets/premium_2026/voice_web_chat_overlay.dart';
import 'widgets/premium_2026/voice_web_owner_stage.dart';
import 'widgets/premium_2026/voice_web_room_header.dart';
import 'widgets/voice_room/voice_room_bottom_dock.dart';
import 'widgets/voice_room_error_boundary.dart';
import '../video/presentation/widgets/room_video_overlay.dart';
import '../video/presentation/widgets/youtube_video_background.dart';
import '../video/presentation/room_video_controller.dart';

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
    _messageCtrl.dispose();
    _messageFocus.dispose();
    unawaited(_audio?.leave());
    _audio?.dispose();
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

  void _sendChatMessage(VoiceRoomEntity room) {
    final text = VoiceOfficialJoin.normalizeCommandInput(
      _messageCtrl.text.trim(),
    );
    if (text.isEmpty) return;
    _messageCtrl.clear();
    _messageFocus.requestFocus();
    unawaited(
      ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).sendMessage(text),
    );
  }

  void _toggleMic() {
    if (_audio == null || !_audioReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ses bağlantısı hazır değil')),
      );
      return;
    }
    final muted = !_isMicMuted;
    _audio?.setMicEnabled(!muted);
    setState(() => _isMicMuted = muted);
    // Mikrofon yalnızca TRTC/LiveKit client-side; backend REST yok.
    // TODO(mic-sync): Socket.IO'da mic/audio-state event'i YOK (mobile/lib/core/socket
    // klasörü de yok). Diğer kullanıcılara mic durumu senkronu için backend'de yeni
    // event/endpoint gerekir — ayrı backend talebi.
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
      setState(() => _fullscreenGift = event);
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

  Future<void> _joinRoom() async {
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
      final perms = VoiceRoomPermissions.forUser(
        user: user,
        room: room,
        server: liveForPerms.serverPermissions,
      );
      await _audio!.join(
        trtcRoomId: room.trtcRoomId,
        userId: user.id,
        isHost: _isRoomOwner(user.id, user.username, room) || perms.isSiteAdmin,
        liveKitRemote: ref.read(liveKitRemoteProvider),
        trtcRemote: ref.read(trtcRemoteProvider),
      );
      if (perms.isSiteAdmin) {
        _audio?.setMicEnabled(true);
      }
      if (mounted) {
        ref.read(voiceRoomDiagnosticProvider.notifier).setTrtc(
              roomId: room.trtcRoomId,
              result: 1,
            );
        ref.read(voiceRoomDiagnosticProvider.notifier).setAudioReady(true);
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
    await ref
        .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
        .leaveRoomSession(source: 'rtc_leave');
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
      await context.push('/voice-room/$key/pk-invite', extra: room.stableSessionKey);
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
    final urls =
        await ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier).fetchBackgrounds();
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
                            .read(voiceRoomLiveProvider(_liveRoomKey).notifier)
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
      showVoiceRoomModerationSheet(
        context: context,
        ref: ref,
        room: effectiveRoom,
        targetUser: VoiceRoomModerationTarget.fromPresence(user),
        isOwnerOrMod: true,
        onGift: openGift,
      );
      return;
    }
    showVoiceUserProfileSheet(
      context,
      user: user,
      isOwner: owner,
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
                      ? NetworkImage(p.image!)
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
    final jeton = VoiceMusicAccess.jetonFromBalances(
      ref.watch(walletBalancesProvider).valueOrNull,
    );
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
    final videoState = ref.watch(roomVideoControllerProvider(_liveRoomKey));
    final videoActive = videoState.hasActiveVideo;
    final speakingIds = <String>{
      for (final p in live.presence)
        if (p.isSpeaking) p.id,
    };
    if (!_isMicMuted && user != null) speakingIds.add(user.id);
    final speakingId = (!_isMicMuted && user != null)
        ? user.id
        : (speakingIds.isNotEmpty ? speakingIds.first : null);
    final bgUrl = live.backgroundUrl ?? room.backgroundImageUrl;
    final staffBanner = live.enterBanner;
    final metrics = VoiceRoomResponsiveMetrics.of(context);
    final keyboardOpen = metrics.keyboardOpen;
    final chatMaxH = metrics.chatBlockH;
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
    });

    ref.listen<VoiceRoomLiveState>(voiceRoomLiveProvider(_liveRoomKey), (prev, next) {
      final q = next.pendingMusicSearchQuery;
      if (q == null || q.isEmpty) return;
      if (prev?.pendingMusicSearchQuery == q) return;
      if (!mounted) return;
      final ctrl = ref.read(voiceRoomLiveProvider(_liveRoomKey).notifier);
      unawaited(() async {
        final hit = await showMusicSearchPickerSheet(context, ref, query: q);
        ctrl.clearPendingMusicSearch();
        if (!mounted || hit == null) return;
        final liveDj = ref.read(voiceRoomLiveProvider(_liveRoomKey)).dj;
        final withVideo = await showMusicModePickerSheet(
          context,
          audioCost: liveDj.musicRequestCost,
          videoCost: liveDj.videoRequestCost,
        );
        if (!mounted || withVideo == null) return;
        final err = await ctrl.submitSelectedSong(hit, withVideo: withVideo);
        if (!mounted || err == null) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }());
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
        unawaited(_joinRoom());
      }
    });

    ref.listen(voiceRoomsProvider, (prev, next) {
      final synced = _roomSynced(next.valueOrNull);
      if (synced.apiRoomKey.isEmpty) return;
      final hadKey = _roomSynced(prev?.valueOrNull).apiRoomKey.isNotEmpty;
      if (!hadKey && !_audioReady && !_leaving) {
        unawaited(_joinRoom());
      }
    });

    ref.listen<VoiceRoomLiveState>(voiceRoomLiveProvider(_liveRoomKey), (prev, next) {
      final wasPlaying =
          (prev?.dj.playing ?? false) && prev?.dj.nowPlaying != null;
      final nowPlaying = next.dj.playing && next.dj.nowPlaying != null;
      if (!wasPlaying && nowPlaying && !isOwner && _audioReady) {
        if (!_isMicMuted) {
          _audio?.setMicEnabled(false);
          setState(() {
            _isMicMuted = true;
            _micAutoMutedByMusic = true;
          });
        }
      } else if (wasPlaying && !nowPlaying && _micAutoMutedByMusic) {
        _audio?.setMicEnabled(true);
        setState(() {
          _isMicMuted = false;
          _micAutoMutedByMusic = false;
        });
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
                              if (videoActive)
                                YoutubeVideoBackground(roomKey: _liveRoomKey),
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
                        RoomVideoOverlay(
                          roomKey: _liveRoomKey,
                          perms: perms,
                          isDj: isDj,
                        ),
                        if (!keyboardOpen)
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
                          child: VoiceWebChatOverlay(
                            messages: live.messages,
                            hideOfficialJoinInChat: staffBanner != null,
                            maxHeight: chatH,
                            embedded: true,
                            welcomeMarquee: staffBanner,
                            roomName: room.nameTr,
                            onUserTap: (id, _) {
                              for (final e in live.presence) {
                                if (e.id == id) {
                                  _openUser(
                                    e,
                                    perms: perms,
                                    room: room,
                                    isOwner: isOwner,
                                  );
                                  break;
                                }
                              }
                            },
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
                                  staffBanner: staffBanner,
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
                  coinBalance: jeton,
                  onSend: () => _sendChatMessage(room),
                  onHome: () => context.go('/voice-rooms'),
                  onToggleAudioOutput: _toggleHeadphones,
                  headphonesOn: ui.headphonesOn,
                  onMicToggle: _toggleMic,
                  micOn: !_isMicMuted,
                  micEnabled: _audioReady,
                  onRoomSettings: () => _openHubSettings(
                    context,
                    room: room,
                    live: live,
                    perms: perms,
                    isOwner: isOwner,
                  ),
                  onUserSettings: () => showVoiceEffectsSheet(context, ref),
                  onTopUp: () => openJetonStore(context, ref: ref),
                  onGiftTap: () => _openGiftShop(
                        context,
                        room: room,
                        presence: live.presence,
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
      ),
    );
  }
}
