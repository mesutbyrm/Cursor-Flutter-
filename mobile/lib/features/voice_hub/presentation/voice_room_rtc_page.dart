import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
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
import '../../live/presentation/gifts/widgets/gift_fullscreen_overlay.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../profile/presentation/providers/profile_providers.dart';
import '../domain/entities/chat_room_presence.dart';
import '../../trtc/presentation/providers/trtc_providers.dart';
import '../domain/entities/voice_audio_engine.dart';
import 'audio/voice_room_audio_coordinator.dart';
import 'providers/chat_room_providers.dart';
import 'providers/voice_gift_providers.dart';
import 'providers/voice_room_audio_providers.dart';
import 'providers/voice_room_ui_provider.dart';
import 'sheets/voice_room_sheets.dart';
import 'theme/voice_room_tokens.dart';
import 'widgets/premium/voice_gift_flight_overlay.dart';
import 'widgets/premium/voice_glass.dart';
import 'widgets/premium/voice_premium_chat.dart';
import 'widgets/premium/voice_premium_controls.dart';
import 'widgets/premium/voice_premium_header.dart';
import 'widgets/premium/voice_premium_stage.dart';
import 'widgets/voice_room/voice_room_announcement.dart';
import 'utils/voice_room_permissions.dart';

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
  var _joining = true;
  var _joined = false;
  String? _error;
  var _micOn = true;
  var _leaving = false;
  VoiceAudioEngineKind? _engineKind;
  LiveGiftEvent? _fullscreenGift;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _joinRoom());
  }

  @override
  void dispose() {
    _giftSub?.cancel();
    _messageCtrl.dispose();
    _audio?.dispose();
    super.dispose();
  }

  void _startGiftRealtime() {
    final service = ref.read(voiceRoomGiftRealtimeProvider);
    service.start(widget.room.id);
    _giftSub?.cancel();
    _giftSub = service.events.listen(_onGiftEvent);
  }

  void _onGiftEvent(LiveGiftEvent event) {
    if (!mounted) return;
    final ui = ref.read(voiceRoomUiProvider);
    if (!ui.giftAnimationsEnabled) return;

    ref.read(voiceGiftFlightQueueProvider.notifier).enqueue(event);

    if (event.coinCost >= 100 || event.combo >= 5) {
      setState(() => _fullscreenGift = event);
      Future.delayed(const Duration(seconds: 3), () {
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
        _joining = false;
        _error = 'Odaya girmek için giriş yapın';
      });
      return;
    }

    _audio = ref.read(voiceRoomAudioCoordinatorProvider);
    if (!_audio!.isSupported) {
      setState(() {
        _joining = false;
        _error = 'Sesli oda bu platformda desteklenmiyor';
      });
      return;
    }

    try {
      final perms = VoiceRoomPermissions.forUser(user: user, room: widget.room);
      _engineKind = await _audio!.join(
        roomId: widget.room.id,
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
          _joining = false;
          _joined = true;
          _micOn = _audio!.micOn;
        });
        _startGiftRealtime();
        _audio?.setHeadphonesOn(ref.read(voiceRoomUiProvider).headphonesOn);
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoiceGlass(
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Oda arka planı',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...urls.map(
              (url) => ListTile(
                leading: const Icon(Icons.image_rounded),
                title: Text(
                  url.split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(voiceRoomLiveProvider(room).notifier)
                      .setRoomBackground(url);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Arka plan güncellendi')),
                    );
                  }
                },
              ),
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final live = ref.watch(voiceRoomLiveProvider(room));
    final ui = ref.watch(voiceRoomUiProvider);
    final flightQueue = ref.watch(voiceGiftFlightQueueProvider);
    final coins = ref.watch(coinBalanceProvider).valueOrNull ??
        ref.watch(authControllerProvider).valueOrNull?.coinBalance ??
        0;
    final online = live.presence.isNotEmpty
        ? live.presence.length
        : room.displayOnline;
    final user = ref.watch(authControllerProvider).valueOrNull;
    final perms = _perms(user, live.presence);
    final isOwner = perms.isRoomOwner || perms.isSiteAdmin;
    final speakingId = _micOn ? user?.id : null;
    final bgUrl = live.backgroundUrl ?? room.backgroundImageUrl;
    final rules = room.descTr?.trim();
    final bottom = MediaQuery.paddingOf(context).bottom;
    final engineLabel = _engineKind == VoiceAudioEngineKind.livekit
        ? 'LiveKit'
        : 'TRTC';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _leave();
      },
      child: Scaffold(
        backgroundColor: VoiceRoomTokens.bgDeep,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _RoomBackground(url: bgUrl),
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
                    if (live.enterBanner != null && live.enterBanner!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                        child: VoiceRoomSystemBanner(message: live.enterBanner!),
                      ),
                    if (rules != null && rules.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                        child: VoiceRoomAnnouncement(text: rules),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                      child: VoicePremiumHeader(
                        room: room,
                        onlineCount: online,
                        isOwner: isOwner,
                        onBack: _leave,
                        onExit: _leave,
                        onShare: _shareRoom,
                        onAudience: () => showVoiceSpeakerListSheet(
                          context,
                          presence: live.presence,
                          room: room,
                          onUserTap: _openUser,
                        ),
                      ),
                    ),
                    if (_engineKind != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Ses: $engineLabel',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: VoicePremiumStage(
                          room: room,
                          presence: live.presence,
                          speakingUserId: speakingId,
                          onUserTap: _openUser,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: VoicePremiumChat(
                          messages: live.messages,
                          onUserTap: (id, name) {
                            ChatRoomPresence? p;
                            for (final e in live.presence) {
                              if (e.id == id) {
                                p = e;
                                break;
                              }
                            }
                            if (p != null) _openUser(p);
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: VoicePremiumMessageBar(
                        controller: _messageCtrl,
                        sending: live.sending,
                        onSend: () {
                          final text = _messageCtrl.text;
                          _messageCtrl.clear();
                          ref
                              .read(voiceRoomLiveProvider(room).notifier)
                              .sendMessage(text);
                        },
                        onGift: () =>
                            showPremiumVoiceGiftShop(context, ref, room: room),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: VoicePremiumControls(
                        micOn: _micOn,
                        headphonesOn: ui.headphonesOn,
                        onMic: () {
                          final next = !_micOn;
                          _audio?.setMicEnabled(next);
                          setState(() => _micOn = next);
                        },
                        onHeadphones: () {
                          final next = !ui.headphonesOn;
                          ref
                              .read(voiceRoomUiProvider.notifier)
                              .toggleHeadphones();
                          _audio?.setHeadphonesOn(next);
                        },
                        onRequestSpeak: () async {
                          final liveCtrl =
                              ref.read(voiceRoomLiveProvider(room).notifier);
                          if (ui.requestSpeakPending) {
                            await liveCtrl.cancelSpeakRequest();
                          } else {
                            await liveCtrl.requestSpeak();
                          }
                          if (context.mounted) {
                            showVoiceRequestSpeakSheet(
                              context,
                              ref,
                              pending: ref.read(voiceRoomUiProvider).requestSpeakPending,
                            );
                          }
                        },
                        onEffects: () => showVoiceEffectsSheet(context, ref),
                        onMore: () => showVoiceMoreMenuSheet(
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
                            ref
                                .read(voiceRoomUiProvider.notifier)
                                .toggleBackgroundMusic();
                            await ref
                                .read(voiceRoomLiveProvider(room).notifier)
                                .toggleBackgroundMusic(enabled);
                          },
                          onPickBackground: perms.canChangeBackground
                              ? () => _pickBackground(context, room)
                              : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 6, 16, bottom + 8),
                      child: Row(
                        children: [
                          Text(
                            '💎 $coins jeton',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: AppColors.diamondBlue,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.push('/jeton-store'),
                            child: const Text('Jeton yükle'),
                          ),
                          TextButton(
                            onPressed: () => ref
                                .read(voiceRoomLiveProvider(room).notifier)
                                .refresh(),
                            child: const Text('Yenile'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            VoiceGiftFlightOverlay(
              events: flightQueue,
              enabled: ui.giftAnimationsEnabled,
              onFinished: (id) =>
                  ref.read(voiceGiftFlightQueueProvider.notifier).dequeue(id),
            ),
            GiftFullscreenOverlay(event: _fullscreenGift),
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
        const DecoratedBox(decoration: BoxDecoration(gradient: VoiceRoomTokens.roomGradient)),
        if (url != null && url!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.6),
            colorBlendMode: BlendMode.darken,
          ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    VoiceRoomTokens.neonPurple.withValues(alpha: 0.12),
                    VoiceRoomTokens.bgDeep.withValues(alpha: 0.95),
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
