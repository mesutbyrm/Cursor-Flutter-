import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

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
import '../../data/services/video_webrtc_signal_service.dart';
import '../providers/co_broadcast_provider.dart';
import '../providers/live_room_interaction_provider.dart'
    show LiveRoomInteractionNotifier, LiveRoomInteractionState, liveRoomInteractionProvider;
import '../providers/live_room_providers.dart';
import '../providers/live_video_pk_provider.dart';
import '../widgets/broadcast_room/live_pk_score_bar.dart';
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

  late Timer _timer;
  Duration _elapsed = Duration.zero;
  final _particlesKey = GlobalKey<FloatingGiftParticlesState>();
  final _heartsKey = GlobalKey<LiveFloatingHeartsOverlayState>();
  Key _localPreviewKey = UniqueKey();
  var _leaving = false;
  VideoWebrtcSignalService? _signalService;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final streamId = widget.session.streamId?.trim();
      if (streamId != null && streamId.isNotEmpty) {
        ref.read(liveRoomInteractionProvider(streamId).notifier)
          ..reset(initialLikes: 0)
          ..loadInitialLikeCount();
      }
      _initTrtc();
      _initGifts();
      _initStreamExtras();
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
      if (widget.session.isHost) {
        _trtc.setMicEnabled(widget.session.initialMicOn);
        _trtc.setCameraEnabled(widget.session.initialCameraOn);
      }
      if (mounted) setState(() => _rtcReady = true);
    } catch (e) {
      if (mounted) {
        setState(() => _rtcError = ApiException.userMessage(e));
      }
    }
  }

  @override
  void dispose() {
    _signalService?.stop();
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

  LiveRoomInteractionNotifier? _interactionNotifier() {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return null;
    return ref.read(liveRoomInteractionProvider(streamId).notifier);
  }

  Future<void> _onFollow() async {
    final hostId = widget.session.hostUserId;
    final notifier = _interactionNotifier();
    if (hostId == null || hostId.isEmpty) {
      notifier?.setFollowing(true);
      return;
    }
    if (notifier == null) return;
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

  void _initStreamExtras() {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    if (widget.session.isHost) {
      unawaited(ref.read(coBroadcastProvider.notifier).refresh());
    }
    _signalService = ref.read(videoWebrtcSignalServiceProvider);
    _signalService?.start(streamId: streamId);
  }

  void _onDoubleTapHeart() {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    ref.read(liveRoomInteractionProvider(streamId).notifier).burstHearts(
          likes: 1,
        );
  }

  Future<void> _openPkPanel() async {
    await context.push('/live/pk-invite', extra: widget.session);
  }

  Future<void> _openHostTools() async {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151522),
      showDragHandle: true,
      builder: (ctx) {
        Future<void> run(Future<void> Function() action, String ok) async {
          try {
            await action();
            if (!ctx.mounted) return;
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
          } catch (e) {
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(ApiException.userMessage(e))),
            );
          }
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text(
                    'Yayın Araçları',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('Web canlı yayın özellikleriyle uyumlu hızlı işlemler'),
                ),
                ListTile(
                  leading: const Icon(Icons.image_rounded),
                  title: const Text('Resim modunu kapak görseliyle güncelle'),
                  onTap: () => run(
                    () => ref.read(liveStreamExtrasProvider).setBroadcastImage(
                          streamId: streamId,
                          imageUrl: widget.session.coverImageUrl ??
                              widget.session.avatarUrl ??
                              'https://canlifal.com/apple-touch-icon.png',
                        ),
                    'Yayın görseli güncellendi.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.wallpaper_rounded),
                  title: const Text('Canlifal arka planı uygula'),
                  onTap: () => run(
                    () => ref.read(liveStreamExtrasProvider).setBackground(
                          streamId: streamId,
                          backgroundUrl: widget.session.backgroundUrl ??
                              'https://canlifal.com/apple-touch-icon.png',
                        ),
                    'Yayın arka planı güncellendi.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.group_add_rounded),
                  title: const Text('Co-broadcast davetlerini yenile'),
                  onTap: () => run(
                    () async {
                      await ref.read(coBroadcastProvider.notifier).refresh();
                    },
                    'Ortak yayın davetleri yenilendi.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.timer_off_rounded),
                  title: const Text('Auto-close kontrolü çalıştır'),
                  onTap: () => run(
                    () => ref.read(liveStreamExtrasProvider).triggerAutoClose(streamId),
                    'Auto-close kontrolü tetiklendi.',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareLive() async {
    final streamId = widget.session.streamId?.trim();
    if (streamId == null || streamId.isEmpty) return;
    final url = 'https://canlifal.com/sohbet/video/broadcast/$streamId';
    await SharePlus.instance.share(
      ShareParams(
        text: '${widget.session.title}\n$url',
        subject: 'Canlifal canlı yayını',
      ),
    );
  }

  String _fmtLikes(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _videoLayer(LiveBroadcastSession s) {
    if (s.isImageMode && s.coverImageUrl?.trim().isNotEmpty == true) {
      return _imageModeLayer(s);
    }
    if (!_rtcReady) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _imageModeLayer(s),
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

  Widget _imageModeLayer(LiveBroadcastSession s) {
    final image = s.coverImageUrl?.trim();
    final bg = s.backgroundUrl?.trim();
    final url = image?.isNotEmpty == true ? image : bg;
    if (url == null || url.isEmpty) return const LiveRoomVideoBackground();
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          errorWidget: (_, _, _) => const LiveRoomVideoBackground(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.62),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _timeLabel {
    final h = _elapsed.inHours.toString().padLeft(2, '0');
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _openHostProfile(BuildContext context, LiveBroadcastSession s) {
    final handle = s.streamerHandle?.trim();
    if (handle != null && handle.isNotEmpty) {
      context.push('/user/${Uri.encodeComponent(handle)}');
      return;
    }
    final id = s.hostUserId;
    if (id != null && id.isNotEmpty) {
      context.push('/user/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseSession = widget.session;
    final streamId = baseSession.streamId?.trim();
    final hasStream = streamId != null && streamId.isNotEmpty;
    final roomState =
        hasStream ? ref.watch(liveRoomProvider(streamId)) : const LiveRoomState();
    final s = baseSession.copyWith(viewerCount: roomState.viewerCount);
    final top = MediaQuery.paddingOf(context).top;
    final giftCtrl = ref.watch(liveGiftControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final interaction = hasStream
        ? ref.watch(liveRoomInteractionProvider(streamId))
        : const LiveRoomInteractionState();
    final pkState = hasStream ? ref.watch(liveVideoPkProvider(streamId)) : null;

    if (hasStream) {
      ref.listen(liveRoomProvider(streamId), (prev, next) {
        if (next.streamEnded && !(prev?.streamEnded ?? false) && !s.isHost) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Yayın sona erdi'),
              content: const Text('Yayıncı yayını kapattı.'),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tamam'),
                ),
              ],
            ),
          );
          if (!mounted) return;
          if (widget.embeddedInSwipe && widget.onSwipeClose != null) {
            widget.onSwipeClose!();
          } else {
            context.go('/live');
          }
        });
        }
      });
    }

    ref.listen<LiveGiftController>(liveGiftControllerProvider, (prev, next) {
      final ev = next.activeFullscreen;
      if (ev != null && ev != prev?.activeFullscreen) {
        final emoji = LiveGiftCatalog.emojiById[ev.giftId] ?? '💖';
        _particlesKey.currentState?.burst(
          emoji,
          count: 6 + ev.combo.clamp(0, 12).toInt(),
        );
        if (hasStream) {
          ref
              .read(liveRoomInteractionProvider(streamId).notifier)
              .pulseHeartsVisual();
          final battle = ref.read(liveVideoPkProvider(streamId)).battle;
          if (battle != null && battle['status'] == 'active') {
            unawaited(ref.read(liveVideoPkProvider(streamId).notifier).refresh());
          }
        }
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
                      onProfileTap: s.hostUserId != null || s.streamerHandle != null
                          ? () => _openHostProfile(context, s)
                          : null,
                      onBack: widget.embeddedInSwipe
                          ? () => unawaited(_confirmEnd(context))
                          : null,
                    ),
                  ),
                  if (hasStream && pkState?.battle != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: LivePkScoreBar(
                        leftScore: pkState!.leftScore,
                        rightScore: pkState.rightScore,
                        status: pkState.status,
                        isHost: s.isHost,
                        onAccept: () => ref
                            .read(liveVideoPkProvider(streamId).notifier)
                            .accept(),
                        onReject: () => ref
                            .read(liveVideoPkProvider(streamId).notifier)
                            .reject(),
                        onEnd: () => ref
                            .read(liveVideoPkProvider(streamId).notifier)
                            .end(),
                      ),
                    )
                  else if (s.isHost)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: _openPkPanel,
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.35),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              icon: const Icon(
                                Icons.sports_mma_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text(
                                'PK Başlat',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _openHostTools,
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.35),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              icon: const Icon(
                                Icons.tune_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: const Text(
                                'Araçlar',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
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
                              LivePremiumChatFeed(
                                messages: roomState.messages.isEmpty
                                    ? const [
                                        LiveRoomChatMessage(
                                          user: 'Sistem',
                                          text: 'Canlı yayına hoş geldin',
                                          isSystem: true,
                                        ),
                                      ]
                                    : roomState.messages,
                              ),
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
                          onShare: _shareLive,
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
                      if (t.isEmpty || streamId == null || streamId.isEmpty) {
                        return;
                      }
                      _chat.clear();
                      unawaited(
                        ref.read(liveRoomProvider(streamId).notifier).sendMessage(
                              t,
                              selfName: user?.display ?? 'Sen',
                            ),
                      );
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
