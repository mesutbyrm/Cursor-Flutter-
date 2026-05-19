import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/user_avatar.dart';
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

/// Aktif canlı yayın — Tencent TRTC video + neon cam katmanlar.
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
  final _messages = <_ChatMsg>[
    const _ChatMsg(
      user: 'Ayşe',
      text: 'Merhaba! Yayına hoş geldin 💜',
      isSystem: false,
    ),
    const _ChatMsg(
      user: 'Sistem',
      text: 'Berk katıldı',
      isSystem: true,
    ),
    const _ChatMsg(user: 'Mehmet', text: 'Harika görünüyorsun!', isSystem: false),
  ];

  late Timer _timer;
  Duration _elapsed = Duration.zero;
  final _particlesKey = GlobalKey<FloatingGiftParticlesState>();

  bool _following = false;

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
      var cred = widget.session.trtc;
      final roomId = widget.session.streamId ?? widget.session.title;
      final resolved = cred ??
          await ref.read(trtcRemoteProvider).fetchUserSig(
                userId: user.id,
                roomId: roomId,
              );

      await _trtc.join(
        credentials: resolved,
        isHost: widget.session.isHost,
        audioOnly: false,
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

  Widget _videoLayer(LiveBroadcastSession s) {
    if (!_rtcReady) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _VideoBackground(),
          if (_rtcError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _rtcError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppDesign.textSecondary),
                ),
              ),
            ),
        ],
      );
    }

    if (s.isHost) {
      return TrtcLocalVideoView(manager: _trtc);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _trtc.remoteVideoAvailable,
      builder: (context, available, _) {
        final anchor = _trtc.remoteAnchorUserId;
        if (available && anchor != null && anchor.isNotEmpty) {
          return TrtcRemoteVideoView(manager: _trtc, userId: anchor);
        }
        return _VideoBackground();
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
        _particlesKey.currentState?.burst(emoji, count: 6 + ev.combo.clamp(0, 12).toInt());
      }
    });

    return Scaffold(
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
                  child: _TopBar(
                    session: s,
                    time: _timeLabel,
                    following: _following,
                    onFollow: () => setState(() => _following = true),
                    onClose: () => _confirmEnd(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      _BadgeChip(
                        icon: Icons.emoji_events_rounded,
                        label: 'Haftalık #12',
                      ),
                      const SizedBox(width: 8),
                      _BadgeChip(
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
                            GiftNotificationStack(events: giftCtrl.notifications),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 160,
                              child: ListView.builder(
                                reverse: true,
                                itemCount: _messages.length,
                                itemBuilder: (ctx, i) {
                                  final m = _messages[_messages.length - 1 - i];
                                  return _ChatBubble(msg: m);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SideActions(
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
                _BottomBar(
                  chatController: _chat,
                  isHost: s.isHost,
                  trtc: s.isHost ? _trtc : null,
                  onGift: () => giftCtrl.setPanelOpen(true),
                  onSend: () {
                    final t = _chat.text.trim();
                    if (t.isEmpty) return;
                    setState(() {
                      _messages.add(_ChatMsg(user: 'Sen', text: t));
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
            style: FilledButton.styleFrom(backgroundColor: AppDesign.liveRed),
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await _trtc.leave();
    final streamId = widget.session.streamId;
    if (widget.session.isHost && streamId != null && streamId.isNotEmpty) {
      try {
        await ref.read(liveRepositoryProvider).endVideoStream(streamId);
      } catch (_) {}
    }
    if (context.mounted) context.pop();
  }
}

class _VideoBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2A1848),
                Color(0xFF120A1C),
                Color(0xFF0A0818),
              ],
            ),
          ),
        ),
        Center(
          child: Icon(
            Icons.videocam_rounded,
            size: 100,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.65),
              ],
              stops: const [0, 0.35, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.session,
    required this.time,
    required this.following,
    required this.onFollow,
    required this.onClose,
  });

  final LiveBroadcastSession session;
  final String time;
  final bool following;
  final VoidCallback onFollow;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppDesign.accentPurple.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              UserAvatar(url: session.avatarUrl, radius: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.streamerName ?? 'Yayıncı',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      '12.5K beğeni',
                      style: TextStyle(
                        color: AppDesign.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (!session.isHost && !following)
                Material(
                  color: AppDesign.accentPink,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onFollow,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Text(
                        '+ Takip Et',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppDesign.liveRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Icon(Icons.visibility_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _formatViewers(session.viewerCount > 0
                        ? session.viewerCount
                        : 4892),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatViewers(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.icon, required this.label});

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
          Icon(icon, size: 14, color: AppDesign.accentCyan),
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

class _ChatMsg {
  const _ChatMsg({
    required this.user,
    required this.text,
    this.isSystem = false,
  });

  final String user;
  final String text;
  final bool isSystem;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.msg});

  final _ChatMsg msg;

  @override
  Widget build(BuildContext context) {
    if (msg.isSystem) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          msg.text,
          style: TextStyle(
            color: AppDesign.accentCyan.withValues(alpha: 0.95),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ProfileGlass(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        borderRadius: 14,
        blur: 8,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12, height: 1.35),
            children: [
              TextSpan(
                text: '${msg.user}: ',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppDesign.accentCyan,
                ),
              ),
              TextSpan(
                text: msg.text,
                style: const TextStyle(color: AppDesign.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideActions extends StatelessWidget {
  const _SideActions({
    required this.likes,
    required this.gifts,
    required this.shares,
    this.onGift,
  });

  final String likes;
  final String gifts;
  final String shares;
  final VoidCallback? onGift;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SideButton(icon: Icons.favorite_rounded, label: likes),
        const SizedBox(height: 12),
        if (onGift != null)
          LiveGiftSideButton(onTap: onGift!)
        else
          _SideButton(icon: Icons.card_giftcard_rounded, label: gifts),
        const SizedBox(height: 12),
        _SideButton(icon: Icons.share_rounded, label: shares),
        const SizedBox(height: 12),
        _SideButton(icon: Icons.person_rounded, label: 'Profil'),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(
              color: AppDesign.accentPurple.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.chatController,
    required this.onSend,
    required this.onEnd,
    required this.isHost,
    this.trtc,
    this.onGift,
  });

  final TextEditingController chatController;
  final VoidCallback onSend;
  final VoidCallback onEnd;
  final bool isHost;
  final TrtcRoomManager? trtc;
  final VoidCallback? onGift;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          color: Colors.black.withValues(alpha: 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isHost && trtc != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MiniControl(
                      icon: trtc!.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      label: 'Mik',
                      onTap: () => trtc!.setMicEnabled(!trtc!.micOn),
                    ),
                    _MiniControl(
                      icon: trtc!.cameraOn
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      label: 'Kam',
                      onTap: () {
                        if (trtc!.cameraOn) {
                          trtc!.stopLocalPreview();
                        }
                      },
                    ),
                    _MiniControl(
                      icon: Icons.cameraswitch_rounded,
                      label: 'Çevir',
                      onTap: trtc!.switchCamera,
                    ),
                    const _MiniControl(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Efekt',
                    ),
                  ],
                ),
              if (isHost) const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Mesaj yaz...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: onSend,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppDesign.accentPink,
                    ),
                  ),
                  if (!isHost && onGift != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onGift,
                      child: const _ActionPill(
                        icon: Icons.card_giftcard_rounded,
                        label: 'Hediye',
                        color: AppDesign.accentPurple,
                      ),
                    ),
                  ],
                  if (isHost) ...[
                    const SizedBox(width: 6),
                    _ActionPill(
                      icon: Icons.card_giftcard_rounded,
                      label: 'Hediye',
                      color: AppDesign.accentPurple,
                    ),
                    const SizedBox(width: 6),
                    _ActionPill(
                      icon: Icons.person_add_rounded,
                      label: 'Davet',
                      color: AppDesign.accentCyan,
                    ),
                    const SizedBox(width: 6),
                    Material(
                      color: AppDesign.liveRed,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: onEnd,
                        borderRadius: BorderRadius.circular(14),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            'Bitir',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniControl extends StatelessWidget {
  const _MiniControl({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

