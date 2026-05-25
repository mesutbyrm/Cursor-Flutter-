import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../live/domain/entities/live_gift_event.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/presentation/providers/live_providers.dart';
import '../domain/entities/chat_room_message.dart';
import '../../gifts/domain/premium_gift_catalog_2026.dart';
import '../../gifts/presentation/widgets/premium_2026/premium_gift_fullscreen_overlay.dart';
import 'providers/voice_gift_combo_tracker.dart';
import 'providers/voice_gift_leaderboard_provider.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../domain/entities/chat_room_presence.dart';
import '../../trtc/presentation/providers/trtc_providers.dart';
import 'audio/voice_room_audio_coordinator.dart';
import 'providers/chat_room_providers.dart';
import 'providers/voice_gift_providers.dart';
import 'providers/voice_room_audio_providers.dart';
import 'providers/voice_room_ui_provider.dart';
import '../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../vip_gold/presentation/widgets/vip_entrance_overlay.dart';
import 'sheets/voice_room_hub_settings.dart';
import 'sheets/voice_room_sheets.dart';
import 'sheets/voice_youtube_song_sheet.dart';
import 'theme/voice_room_tokens.dart';
import 'utils/voice_room_permissions.dart';
import 'widgets/premium/voice_gift_flight_overlay.dart';
import 'widgets/premium/voice_glass.dart';
import 'widgets/premium_2026/voice_cosmic_background.dart';
import 'widgets/premium_2026/voice_room_audience_strip.dart';
import 'widgets/premium_2026/voice_web_bottom_nav.dart';
import 'widgets/premium_2026/voice_web_chat_overlay.dart';
import 'widgets/premium_2026/voice_timed_duyuru.dart';
import 'widgets/premium_2026/voice_web_owner_stage.dart';
import 'widgets/premium_2026/voice_web_room_header.dart';
import 'widgets/voice_room/voice_room_action_row.dart';
import 'widgets/voice_room/voice_room_announcement.dart'
    show VoiceRoomSystemBanner;
import 'widgets/voice_room/voice_staff_entrance_marquee.dart';
import 'widgets/voice_room_gift_sheet.dart';

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
  var _chatOutbound = false;
  final _messageFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(voiceRoomsProvider);
      _joinRoom();
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

  Future<void> _sendChatMessage(VoiceRoomEntity room) async {
    final text = _messageCtrl.text.trim();
    if (text.isEmpty || _chatOutbound) return;
    _chatOutbound = true;
    _messageCtrl.clear();
    try {
      await ref.read(voiceRoomLiveProvider(room).notifier).sendMessage(text);
      if (!mounted) return;
      final err = ref.read(voiceRoomLiveProvider(room)).error;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    } finally {
      _chatOutbound = false;
    }
  }

  void _startGiftRealtime() {
    final service = ref.read(voiceRoomGiftRealtimeProvider);
    service.start(widget.room.id);
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
      return;
    }

    try {
      final perms = VoiceRoomPermissions.forUser(user: user, room: widget.room);
      final roomKey = widget.room.apiRoomKey;
      await _audio!.join(
        roomId: roomKey.isNotEmpty ? roomKey : widget.room.id,
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _audioJoining = false;
          _audioError = ApiException.userMessage(e);
        });
        _startGiftRealtime();
        _maybeShowVipEntrance(user);
      }
    }
  }

  void _maybeShowVipEntrance(UserEntity user) {
    if (_vipEntrancePlayed || !mounted) return;
    final tier = ref.read(vipTierProvider);
    if (!tier.hasEntranceFx) return;
    _vipEntrancePlayed = true;
    setState(() => _showVipEntrance = true);
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    ref.read(voiceRoomGiftRealtimeProvider).stop();
    await _audio?.leave();
    if (mounted) context.go('/voice-rooms');
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
                  color: AppColors.textMuted.withValues(alpha: 0.9),
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
                            Image.network(url, fit: BoxFit.cover),
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

  void _openMoreMenu(
    BuildContext context, {
    required VoiceRoomEntity room,
    required VoiceRoomLiveState live,
    required VoiceRoomPermissions perms,
    required bool isOwner,
    required VoiceRoomUiState ui,
  }) {
    showVoiceMoreMenuSheet(
      context,
      ref: ref,
      room: room,
      live: live,
      perms: perms,
      onSettings: () => showVoiceRoomSettingsSheet(
        context,
        ref,
        room: room,
        isOwner: isOwner,
        perms: perms,
        presence: live.presence,
        onUserTap: _openUser,
      ),
      onSpeakers: () => showVoiceSpeakerListSheet(
        context,
        presence: live.presence,
        room: room,
        onUserTap: _openUser,
      ),
      onShare: _shareRoom,
      onBackgroundMusic: () async {
        final enabled = !ui.backgroundMusicEnabled;
        ref.read(voiceRoomUiProvider.notifier).toggleBackgroundMusic();
        final err = await ref
            .read(voiceRoomLiveProvider(room).notifier)
            .toggleBackgroundMusic(enabled);
        if (context.mounted && err != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      },
      onPickBackground: perms.canChangeBackground
          ? () => _pickBackground(context, room)
          : null,
      onPkBattle: () => context.push(
        '/voice-room/${room.apiRoomKey}/pk',
        extra: room,
      ),
      onGoldVip: () => context.push('/vip-gold'),
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
    final speakingId = _micOn ? user?.id : null;
    final bgUrl = live.backgroundUrl ?? room.backgroundImageUrl;
    final staffBanner = live.enterBanner != null &&
            (live.enterBanner!.contains('STAFF') ||
                live.enterBanner!.contains('VIP'))
        ? live.enterBanner
        : null;
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final keyboardOpen = viewInsets.bottom > 0;
    final mq = MediaQuery.sizeOf(context);
    final audience = voiceWebAudienceOffStage(presence: live.presence, room: room);
    final chatMaxH = keyboardOpen
        ? (mq.height * 0.26).clamp(110.0, 180.0)
        : (mq.height * 0.32).clamp(140.0, 260.0);
    final duyuru = (room.descTr ?? room.rulesTr)?.trim();
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
    String? lastJoinBanner;
    for (var i = live.messages.length - 1; i >= 0; i--) {
      final m = live.messages[i];
      if (m.kind == ChatMessageKind.systemJoin) {
        lastJoinBanner = m.content;
        break;
      }
    }

    ref.listen<VoiceRoomLiveState>(voiceRoomLiveProvider(room), (prev, next) {
      if (prev?.error != next.error && next.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
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
                            color: AppColors.liveRed.withValues(alpha: 0.15),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.headset_off_rounded,
                                color: AppColors.liveRed,
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
                                color: AppColors.liveRed,
                                fontSize: 11,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (!keyboardOpen)
                          VoiceStaffEntranceMarquee(message: staffBanner),
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
                        const SizedBox(height: 4),
                        VoiceWebRoomInfoPill(
                          room: room,
                          ownerName: ownerName,
                          ownerAvatarUrl: ownerAvatar,
                        ),
                        if (!keyboardOpen) ...[
                          if (duyuru?.isNotEmpty == true)
                            VoiceTimedDuyuru(
                              roomKey: room.apiRoomKey,
                              text: duyuru!,
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: VoiceRoomActionRow(
                              dj: live.dj,
                              onMusicTap: () => showVoiceYoutubeSongSheet(
                                context,
                                ref,
                                room: room,
                              ),
                              onDjTap: () => _openHubSettings(
                                context,
                                room: room,
                                live: live,
                                perms: perms,
                                isOwner: isOwner,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          VoiceRoomAudienceStrip(
                            audience: audience,
                            totalOnline: online,
                            onUserTap: _openUser,
                          ),
                          if (lastJoinBanner != null) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: VoiceRoomSystemBanner(
                                message: lastJoinBanner,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: VoiceWebChatOverlay(
                        messages: live.messages,
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
            : Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VoiceWebChatInputBar(
                      controller: _messageCtrl,
                      focusNode: _messageFocus,
                      sending: live.sending,
                      onSend: () => unawaited(_sendChatMessage(room)),
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
                        onCoins: () => context.push('/jeton-store'),
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
    );
  }
}
