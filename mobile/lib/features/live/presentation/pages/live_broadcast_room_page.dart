import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../gifts/presentation/widgets/premium_gift_panel.dart';
import '../../../moderation/domain/entities/report_target.dart';
import '../../../moderation/presentation/utils/open_report_flow.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../profile/presentation/widgets/premium/profile_glass.dart';
import '../../../trtc/presentation/providers/trtc_providers.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../domain/entities/live_broadcast_session.dart';
import '../../domain/entities/live_gift_catalog.dart';
import '../gifts/live_gift_controller.dart';
import '../gifts/providers/live_gift_providers.dart';
import '../gifts/widgets/floating_gift_particles.dart';
import '../gifts/widgets/gift_fullscreen_overlay.dart';
import '../gifts/widgets/gift_notification_stack.dart';
import '../providers/live_providers.dart';
import '../providers/live_room_interaction_provider.dart';
import '../widgets/broadcast_room/live_room_chat_message.dart';
import '../widgets/broadcast_room/live_room_video_background.dart';
import '../widgets/premium_2026/live_premium_2026.dart';

/// Premium 2026 canlı yayın — TRTC + immersive overlay + hediye + kalpler.
class LiveBroadcastRoomPage extends ConsumerStatefulWidget {
  const LiveBroadcastRoomPage({
    super.key,
    required this.session,
    this.embeddedInSwipe = false,
    this.onSwipeClose,
  });

  final LiveBroadcastSession session;
  final bool embeddedInSwipe;
  final VoidCallback? onSwipeClose;

  @override
  ConsumerState<LiveBroadcastRoomPage> createState() =>
      _LiveBroadcastRoomPageState();
}

class _LiveBroadcastRoomPageState extends ConsumerState<LiveBroadcastRoomPage> {
  final _trtc = TrtcRoomManager();
  var _rtcReady = false;
  String? _rtcError;
  final _chat = TextEditingController();
  final _messages = <LiveRoomChatMessage>[
    const LiveRoomChatMessage(
      user: 'Ayşe',
      text: 'Merhaba! Yayına hoş geldin 💜',
    ),
    const LiveRoomChatMessage(
      user: 'Sistem',
      text: 'Canlı yayına hoş geldin',
      isSystem: true,
    ),
  ];

  late Timer _timer;
  Duration _elapsed = Duration.zero;
  final _particlesKey = GlobalKey<FloatingGiftParticlesState>();
  final _heartsKey = GlobalKey<LiveFloatingHeartsOverlayState>();
  Key _localPreviewKey = UniqueKey();
  var _leaving = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(liveRoomInteractionProvider.notifier).reset(initialLikes: 12500);
      _initTrtc();
      _initGifts();
    });
  }

  void _initGifts() {
    final streamId = widget.session.streamId;
    if (streamId == null || streamId.isEmpty) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    ref.read(liveGiftControllerProvider).attach(
          streamId: streamId,
          receiverName: widget.session.streamerName ?? 'Yayıncı',
          initialCoins: user?.coinBalance,
        );
  }

  Future<void> _initTrtc() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null || !_trtc.isSupported) return;

    try {
      final roomId = widget.session.streamId?.trim();
      if (roomId == null || roomId.isEmpty) {
        throw StateError('Yayın odası kimliği eksik');
      }

      var cred = widget.session.trtc;
      if (cred == null || !cred.matchesRoom(roomId)) {
        cred = await ref.read(trtcRemoteProvider).fetchUserSig(
              userId: user.id,
              roomId: roomId,
            );
      }

      final anchorHint = widget.session.isHost
          ? cred.userId
          : (widget.session.hostUserId?.trim().isNotEmpty == true
              ? widget.session.hostUserId
              : null);

      await _trtc.join(
        credentials: cred,
        isHost: widget.session.isHost,
        audioOnly: false,
        expectedAnchorUserId: anchorHint,
      );
      if (mounted) setState(() => _rtcReady = true);
    } catch (e) {
      if (mounted) {
        setState(() => _rtcError = ApiException.userMessage(e));
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _chat.dispose();
    _trtc.dispose();
    super.dispose();
  }

  Future<void> _exitBroadcast(BuildContext context) async {
    if (_leaving) return;
    _leaving = true;
    ref.read(liveGiftControllerProvider).detach();
    await _trtc.leave();
    final streamId = widget.session.streamId;
    if (widget.session.isHost && streamId != null && streamId.isNotEmpty) {
      try {
        await ref.read(liveRepositoryProvider).endVideoStream(streamId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Yayın sunucuda kapatılamadı: ${ApiException.userMessage(e)}',
              ),
            ),
          );
        }
      }
    }
    ref.invalidate(liveStreamsProvider);
    if (!context.mounted) return;
    if (widget.embeddedInSwipe && widget.onSwipeClose != null) {
      widget.onSwipeClose!();
    } else {
      context.go('/feed');
    }
  }

  Future<void> _onFollow() async {
    final hostId = widget.session.hostUserId;
    if (hostId == null || hostId.isEmpty) {
      ref.read(liveRoomInteractionProvider.notifier).setFollowing(true);
      return;
    }
    final notifier = ref.read(liveRoomInteractionProvider.notifier);
    notifier.setFollowLoading(true);
    try {
      await ref.read(profileRepositoryProvider).follow(hostId);
      notifier.setFollowing(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      notifier.setFollowLoading(false);
    }
  }

  void _onDoubleTapHeart() {
    ref.read(liveRoomInteractionProvider.notifier).burstHearts(likes: 3);
  }

  String _fmtLikes(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _videoLayer(LiveBroadcastSession s) {
    if (!_rtcReady) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const LiveRoomVideoBackground(),
          if (_rtcError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _rtcError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
        ],
      );
    }

    if (s.isHost) {
      return TrtcLocalVideoView(key: _localPreviewKey, manager: _trtc);
    }

    return ValueListenableBuilder<String?>(
      valueListenable: _trtc.remoteAnchorUserIdNotifier,
      builder: (context, anchor, _) {
        if (anchor != null && anchor.isNotEmpty) {
          return TrtcRemoteVideoView(
            key: ValueKey(anchor),
            manager: _trtc,
            userId: anchor,
          );
        }
        return const LiveRoomVideoBackground();
      },
    );
  }

  String get _timeLabel {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final top = MediaQuery.paddingOf(context).top;
    final giftCtrl = ref.watch(liveGiftControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final interaction = ref.watch(liveRoomInteractionProvider);

    ref.listen<LiveGiftController>(liveGiftControllerProvider, (prev, next) {
      final ev = next.activeFullscreen;
      if (ev != null && ev != prev?.activeFullscreen) {
        final emoji = LiveGiftCatalog.emojiById[ev.giftId] ?? '💖';
        _particlesKey.currentState?.burst(
          emoji,
          count: 6 + ev.combo.clamp(0, 12).toInt(),
        );
        ref.read(liveRoomInteractionProvider.notifier).burstHearts(likes: 2);
      }
    });

    return PopScope(
      canPop: widget.embeddedInSwipe,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmEnd(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _videoLayer(s)),
            const LiveImmersiveScrim(),
            LiveFloatingHeartsOverlay(
              key: _heartsKey,
              burstToken: interaction.heartBurstToken,
              onDoubleTap: _onDoubleTapHeart,
            ),
            FloatingGiftParticles(key: _particlesKey),
            GiftFullscreenOverlay(event: giftCtrl.activeFullscreen),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, top > 0 ? 4 : 12, 12, 0),
                    child: LivePremiumTopBar(
                      session: s,
                      time: _timeLabel,
                      following: interaction.following,
                      followLoading: interaction.followLoading,
                      onFollow: _onFollow,
                      onClose: () => _confirmEnd(context),
                      onBack: widget.embeddedInSwipe
                          ? () => widget.onSwipeClose?.call()
                          : null,
                    ),
                  ),
                  if (s.isHost)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          _HostBadge(
                            icon: Icons.emoji_events_rounded,
                            label: 'Haftalık #12',
                          ),
                          const SizedBox(width: 8),
                          _HostBadge(
                            icon: Icons.explore_rounded,
                            label: 'Keşfet',
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GiftNotificationStack(
                                events: giftCtrl.notifications,
                              ),
                              const SizedBox(height: 8),
                              LivePremiumChatFeed(messages: _messages),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        LivePremiumSideRail(
                          likeLabel: _fmtLikes(interaction.likeCount),
                          giftLabel: giftCtrl.streamerEarnings != null
                              ? '${giftCtrl.streamerEarnings}'
                              : 'Hediye',
                          shareLabel: 'Paylaş',
                          onLike: _onDoubleTapHeart,
                          onGift: () => giftCtrl.setPanelOpen(true),
                          onReport: s.streamId != null && s.streamId!.isNotEmpty
                              ? () => openReportFlow(
                                    context,
                                    ReportTarget(
                                      type: ReportTargetType.liveStream,
                                      targetId: s.streamId!,
                                      displayTitle:
                                          s.streamerName ?? 'Canlı yayın',
                                    ),
                                  )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  LivePremiumBottomBar(
                    chatController: _chat,
                    isHost: s.isHost,
                    trtc: s.isHost ? _trtc : null,
                    onToggleCamera: s.isHost
                        ? () {
                            if (_trtc.cameraOn) {
                              _trtc.stopLocalPreview();
                            } else {
                              setState(() => _localPreviewKey = UniqueKey());
                            }
                            setState(() {});
                          }
                        : null,
                    onGift: () => giftCtrl.setPanelOpen(true),
                    onSend: () {
                      final t = _chat.text.trim();
                      if (t.isEmpty) return;
                      setState(() {
                        _messages.add(LiveRoomChatMessage(user: 'Sen', text: t));
                        _chat.clear();
                      });
                    },
                    onEnd: s.isHost ? () => _confirmEnd(context) : null,
                  ),
                ],
              ),
            ),
            if (giftCtrl.panelOpen && user != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PremiumGiftPanel(
                  controller: giftCtrl,
                  streamId: widget.session.streamId ?? '',
                  senderName: user.display,
                  senderId: user.id,
                  onClose: () => giftCtrl.setPanelOpen(false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmEnd(BuildContext context) async {
    if (widget.embeddedInSwipe && widget.onSwipeClose != null) {
      widget.onSwipeClose!();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Yayını bitir?'),
        content: const Text('Canlı yayından çıkmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.liveRed),
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _exitBroadcast(context);
  }
}

class _HostBadge extends StatelessWidget {
  const _HostBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ProfileGlass(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 14,
      blur: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accentCyan),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
