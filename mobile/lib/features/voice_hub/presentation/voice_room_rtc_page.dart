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
import '../../trtc/presentation/providers/trtc_providers.dart';
import 'audio/voice_room_audio_coordinator.dart';
import 'providers/chat_room_providers.dart';
import 'providers/pk_battle_remote_provider.dart';
import 'utils/voice_room_image_prefetch.dart';
import 'providers/voice_gift_providers.dart';
import 'providers/voice_room_audio_providers.dart';
import 'providers/voice_room_diagnostic_provider.dart';
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
import 'widgets/voice_room/voice_room_music_queue_section.dart';
import 'widgets/voice_room/voice_room_right_slide_panel.dart';
import 'widgets/voice_room/voice_room_spec_footer.dart';
import 'sheets/voice_room_commands_panel.dart';
import 'sheets/voice_room_dj_sheet.dart';
import 'widgets/premium_2026/voice_room_persistent_duyuru.dart';
import 'widgets/premium_2026/voice_web_chat_overlay.dart';
import 'widgets/premium_2026/voice_web_owner_stage.dart';
import 'widgets/premium_2026/voice_web_room_header.dart';
import 'widgets/voice_room/voice_room_action_row.dart';
import 'widgets/voice_room/voice_room_music_mini_player.dart';
import 'widgets/voice_room/voice_staff_entrance_marquee.dart';
import 'widgets/voice_room/voice_room_music_request_flash.dart';
import 'widgets/voice_room_error_boundary.dart';

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
  /// Provider oturum anahtarı — online sayısı değişince yeniden kurulmasın.
  VoiceRoomEntity? _pinnedLiveSession;

  VoiceRoomEntity _resolveSession(VoiceRoomEntity room) {
    if (_pinnedLiveSession != null &&
        _pinnedLiveSession!.apiRoomKey.isNotEmpty) {
      return _pinnedLiveSession!;
    }
    final base = room.apiRoomKey.isNotEmpty ? room : widget.room;
    if (base.apiRoomKey.isNotEmpty) {
      _pinnedLiveSession = base.stableSessionKey;
      return _pinnedLiveSession!;
    }
    return base.stableSessionKey;
  }

  VoiceRoomEntity get _sessionRoom =>
      _resolveSession(_effectiveRoom());

  @override
  void initState() {
    super.initState();
    if (widget.room.apiRoomKey.isNotEmpty) {
      _pinnedLiveSession = widget.room.stableSessionKey;
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
    final bg = ref.read(voiceRoomLiveProvider(_sessionRoom)).backgroundUrl ??
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
      await ref.read(voiceRoomLiveProvider(_sessionRoom).notifier).sendMessage(text);
      if (!mounted) return;
      final err = ref.read(voiceRoomLiveProvider(_sessionRoom)).error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }());
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
      _pinnedLiveSession = room.stableSessionKey;
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
      final perms = VoiceRoomPermissions.forUser(user: user, room: room);
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
          _micOn = _audio!.micOn;
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
    final r = widget.room;
    final roomKey = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
    final remote = ref.read(pkBattleRemoteProvider.notifier);
    await remote.loadRoomBattle(roomKey);
    if (!mounted) return;
    final battle = ref.read(pkBattleRemoteProvider);
    if (battle == null || battle.isEnded) return;
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
      room: _effectiveRoom(),
      selfPresence: self,
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
        await ref.read(voiceRoomLiveProvider(_sessionRoom).notifier).fetchBackgrounds();
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
                            .read(voiceRoomLiveProvider(_sessionRoom).notifier)
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
          .read(voiceRoomLiveProvider(_sessionRoom).notifier)
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
                      .read(voiceRoomLiveProvider(_sessionRoom).notifier)
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
                      .read(voiceRoomLiveProvider(_sessionRoom).notifier)
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
    final liveCtrl = ref.read(voiceRoomLiveProvider(_sessionRoom).notifier);
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
        final ctrl = ref.read(voiceRoomLiveProvider(_sessionRoom).notifier);
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
    final session = _resolveSession(room);
    final live = ref.watch(voiceRoomLiveProvider(session));
    final diagnostic = ref.watch(voiceRoomDiagnosticProvider);
    final ui = ref.watch(voiceRoomUiProvider);
    final flightQueue = ref.watch(voiceGiftFlightQueueProvider);
    final online = live.onlineCountFor(room);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final perms = _perms(user, live.presence);
    final isOwner = perms.isRoomOwner || perms.isSiteAdmin;
    final jeton = VoiceMusicAccess.jetonFromBalances(
      ref.watch(walletBalancesProvider).valueOrNull,
    );
    final isDj = perms.canManageDj ||
        live.dj.canPlayMusic ||
        (user != null && room.djUserIds.contains(user.id));
    final showDjControls = isOwner || isDj;
    final showMusicCard = showDjControls &&
        VoiceMusicAccess.canShowMusicCard(
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
    final headerAvatar = ownerPresence?.image ?? room.ownerAvatarUrl;
    ref.listen<VoiceRoomLiveState>(voiceRoomLiveProvider(session), (prev, next) {
      if (prev?.error != next.error && next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
      if (next.openCommandsPanel && !(prev?.openCommandsPanel ?? false)) {
        ref.read(voiceRoomLiveProvider(session).notifier).clearOpenCommandsPanel();
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
          ref.read(voiceRoomLiveProvider(session).notifier).refresh(includeDj: true),
        );
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
                          onRoomPanel: () => showVoiceSpeakerListSheet(
                            context,
                            presence: live.presence,
                            room: room,
                            onUserTap: _openUser,
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            physics: const ClampingScrollPhysics(),
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
                        if (!keyboardOpen) ...[
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
                          VoiceRoomMusicMiniPlayer(
                            dj: live.dj,
                            canModerate: perms.canModerate || isOwner,
                            canControl: perms.canManageDj ||
                                isOwner ||
                                live.dj.canPlayMusic,
                            onTap: showMusicCard
                                ? () => showVoiceMusicHubPage(
                                      context,
                                      ref,
                                      room: room,
                                      perms: perms,
                                      isOwner: isOwner,
                                    )
                                : null,
                            onPlayPause: () {
                              final ctrl = ref
                                  .read(voiceRoomLiveProvider(_sessionRoom).notifier);
                              final playing = live.dj.playing ||
                                  ref
                                      .read(voiceRoomDjPlayerProvider)
                                      .playback
                                      .value
                                      .playing;
                              unawaited(
                                playing ? ctrl.pauseMusic() : ctrl.resumeMusic(),
                              );
                            },
                            onStop: () => unawaited(
                              ref
                                  .read(voiceRoomLiveProvider(_sessionRoom).notifier)
                                  .stopMusic(),
                            ),
                            onSkip: (perms.canModerate || isOwner)
                                ? () => ref
                                    .read(voiceRoomLiveProvider(_sessionRoom).notifier)
                                    .skipMusic()
                                : null,
                          ),
                          if (showDjControls)
                            Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: VoiceRoomActionRow(
                              dj: live.dj,
                              showMusicCard: showMusicCard,
                              showDjCard: showDjControls,
                              showPkCard: isOwner,
                              pkActive:
                                  ref.watch(pkBattleRemoteProvider)?.isActive ==
                                      true,
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
                              onPkTap: () {
                                final active = ref.read(pkBattleRemoteProvider);
                                if (active?.isActive == true) {
                                  _openActivePk(room);
                                } else {
                                  _openPkInvite(room);
                                }
                              },
                            ),
                          ),
                          VoiceRoomMusicQueueSection(
                            dj: live.dj,
                            coinCost: live.dj.musicRequestCost,
                          ),
                          VoiceRoomMusicRequestFlash(
                            message: live.musicRequestFlash,
                          ),
                        ],
                            ],
                          ),
                        ),
                        Align(
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
                      ],
                    ),
                  ),
                ),
                AnimatedPadding(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: VoiceRoomSpecFooter(
                    controller: _messageCtrl,
                    focusNode: _messageFocus,
                    coinBalance: jeton,
                    sending: live.sending,
                    onSend: () => _sendChatMessage(room),
                    onRefresh: () => ref
                        .read(voiceRoomLiveProvider(session).notifier)
                        .refresh(includeDj: true),
                    onShare: _shareRoom,
                    onTopUp: () => openJetonStore(context, ref: ref),
                    onGiftTap: () =>
                        showPremiumVoiceGiftShop(context, ref, room: room),
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
            if (!keyboardOpen)
              VoiceRoomRightSlidePanel(
                room: room,
                perms: perms,
                isOwner: isOwner,
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
      ),
    );
  }
}
