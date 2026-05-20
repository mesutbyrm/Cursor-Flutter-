import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
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
import '../gifts/widgets/live_gift_panel.dart';
import '../providers/live_providers.dart';
import '../widgets/broadcast_room/live_room_bottom_bar.dart';
import '../widgets/broadcast_room/live_room_chat_message.dart';
import '../widgets/broadcast_room/live_room_chat_panel.dart';
import '../widgets/broadcast_room/live_room_side_actions.dart';
import '../widgets/broadcast_room/live_room_top_bar.dart';
import '../widgets/broadcast_room/live_room_video_background.dart';

/// Aktif canlı yayın — TRTC + modüler premium katmanlar.
class LiveBroadcastRoomPage extends ConsumerStatefulWidget {
  const LiveBroadcastRoomPage({super.key, required this.session});

  final LiveBroadcastSession session;

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
    const LiveRoomChatMessage(user: 'Sistem', text: 'Berk katıldı', isSystem: true),
    const LiveRoomChatMessage(user: 'Mehmet', text: 'Harika görünüyorsun!'),
  ];

  late Timer _timer;
  Duration _elapsed = Duration.zero;
  final _particlesKey = GlobalKey<FloatingGiftParticlesState>();
  Key _localPreviewKey = UniqueKey();
  var _leaving = false;
  var _following = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTrtc();
      _initGifts();
    });
  }

  void _initGifts() {
    final streamId = widget.session.streamId;
    if (streamId == null || streamId.isEmpty) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    final gifts = ref.read(liveGiftControllerProvider);
    gifts.attach(
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
    context.go('/feed');
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
    final bottom = MediaQuery.paddingOf(context).bottom;
    final giftCtrl = ref.watch(liveGiftControllerProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;

    ref.listen<LiveGiftController>(liveGiftControllerProvider, (prev, next) {
      final ev = next.activeFullscreen;
      if (ev != null && ev != prev?.activeFullscreen) {
        final emoji = LiveGiftCatalog.emojiById[ev.giftId] ?? '💖';
        _particlesKey.currentState?.burst(
          emoji,
          count: 6 + ev.combo.clamp(0, 12).toInt(),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmEnd(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: _videoLayer(s)),
            FloatingGiftParticles(key: _particlesKey),
            GiftFullscreenOverlay(event: giftCtrl.activeFullscreen),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(12, top > 0 ? 4 : 12, 12, 0),
                    child: LiveRoomTopBar(
                      session: s,
                      time: _timeLabel,
                      following: _following,
                      onFollow: () => setState(() => _following = true),
                      onClose: () => _confirmEnd(context),
                    ),
                  ),
                  if (s.isHost)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                              const SizedBox(height: 10),
                              LiveRoomChatPanel(messages: _messages),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        LiveRoomSideActions(
                          likes: '12.5K',
                          gifts: giftCtrl.streamerEarnings != null
                              ? '${giftCtrl.streamerEarnings}'
                              : '3.245',
                          shares: '1.245',
                          onGift: () => giftCtrl.setPanelOpen(true),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: bottom + 8),
                  LiveRoomBottomBar(
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
                    onEnd: () => _confirmEnd(context),
                  ),
                ],
              ),
            ),
            if (giftCtrl.panelOpen && user != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LiveGiftPanel(
                  controller: giftCtrl,
                  senderName: user.displayName ?? user.username,
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
