import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_design.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/presentation/widgets/premium/profile_glass.dart';
import '../../domain/entities/live_broadcast_session.dart';

/// Aktif canlı yayın — video üzerinde neon cam katmanlar.
class LiveBroadcastRoomPage extends StatefulWidget {
  const LiveBroadcastRoomPage({super.key, required this.session});

  final LiveBroadcastSession session;

  @override
  State<LiveBroadcastRoomPage> createState() => _LiveBroadcastRoomPageState();
}

class _LiveBroadcastRoomPageState extends State<LiveBroadcastRoomPage>
    with TickerProviderStateMixin {
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
  late AnimationController _floatCtrl;
  final _floats = <_FloatingGift>[];
  final _rand = Random();

  bool _following = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _spawnFloats();
  }

  void _spawnFloats() {
    Timer.periodic(const Duration(milliseconds: 1400), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _floats.add(_FloatingGift(
          id: _rand.nextInt(1 << 30),
          emoji: _rand.nextBool() ? '💖' : '🌹',
          left: 0.55 + _rand.nextDouble() * 0.35,
        ));
        if (_floats.length > 12) _floats.removeAt(0);
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _floatCtrl.dispose();
    _chat.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _VideoBackground(),
          ..._floats.map((f) => _FloatingHeartWidget(
                key: ValueKey(f.id),
                gift: f,
                controller: _floatCtrl,
              )),
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
                            _GiftStack(),
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
                        gifts: '3.245',
                        shares: '1.245',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: bottom + 8),
                _BottomBar(
                  chatController: _chat,
                  isHost: s.isHost,
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
    if (ok == true && context.mounted) context.pop();
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

class _GiftStack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const gifts = [
      ('Ayşe', '🌹', 'x12'),
      ('Mehmet', '💖', 'x23'),
      ('Zeynep', '⭐', 'x8'),
    ];
    return Column(
      children: [
        for (final g in gifts) _GiftNotice(name: g.$1, emoji: g.$2, mult: g.$3),
      ],
    );
  }
}

class _GiftNotice extends StatelessWidget {
  const _GiftNotice({
    required this.name,
    required this.emoji,
    required this.mult,
  });

  final String name;
  final String emoji;
  final String mult;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ProfileGlass(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        borderRadius: 16,
        blur: 10,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              mult,
              style: const TextStyle(
                color: AppDesign.accentPink,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
  });

  final String likes;
  final String gifts;
  final String shares;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SideButton(icon: Icons.favorite_rounded, label: likes),
        const SizedBox(height: 12),
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
  });

  final TextEditingController chatController;
  final VoidCallback onSend;
  final VoidCallback onEnd;
  final bool isHost;

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
              if (isHost)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MiniControl(icon: Icons.mic_rounded, label: 'Mik'),
                    _MiniControl(icon: Icons.videocam_rounded, label: 'Kam'),
                    _MiniControl(icon: Icons.cameraswitch_rounded, label: 'Çevir'),
                    _MiniControl(icon: Icons.auto_awesome_rounded, label: 'Efekt'),
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
  const _MiniControl({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
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

class _FloatingGift {
  _FloatingGift({required this.id, required this.emoji, required this.left});

  final int id;
  final String emoji;
  final double left;
}

class _FloatingHeartWidget extends StatelessWidget {
  const _FloatingHeartWidget({
    super.key,
    required this.gift,
    required this.controller,
  });

  final _FloatingGift gift;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, child) {
        final t = (controller.value + gift.id % 100 / 100) % 1.0;
        return Positioned(
          left: MediaQuery.sizeOf(context).width * gift.left,
          bottom: h * 0.15 + t * h * 0.55,
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Text(
              gift.emoji,
              style: TextStyle(fontSize: 20 + t * 12),
            ),
          ),
        );
      },
    );
  }
}
