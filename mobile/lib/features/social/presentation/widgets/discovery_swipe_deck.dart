import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/social_discovery_user.dart';
import 'discovery_social_user_card.dart';

/// Tinder tarzı keşif destesi — üstteki kart kaydırılır (beğen / geç).
class DiscoverySwipeDeck extends StatefulWidget {
  const DiscoverySwipeDeck({
    super.key,
    required this.users,
    required this.onLike,
    required this.onSkip,
    required this.onOpenProfile,
    this.onReport,
  });

  final List<SocialDiscoveryUser> users;
  final Future<void> Function(SocialDiscoveryUser user) onLike;
  final Future<void> Function(SocialDiscoveryUser user) onSkip;
  final void Function(SocialDiscoveryUser user) onOpenProfile;
  final void Function(SocialDiscoveryUser user)? onReport;

  @override
  State<DiscoverySwipeDeck> createState() => _DiscoverySwipeDeckState();
}

class _DiscoverySwipeDeckState extends State<DiscoverySwipeDeck>
    with SingleTickerProviderStateMixin {
  var _index = 0;
  Offset _drag = Offset.zero;
  late AnimationController _snap;
  Animation<Offset>? _snapAnim;

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_snapAnim != null) {
          setState(() => _drag = _snapAnim!.value);
        }
      });
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DiscoverySwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.users.length) {
      _index = 0;
      _drag = Offset.zero;
    }
  }

  bool get _empty => _index >= widget.users.length;

  SocialDiscoveryUser? get _top =>
      _empty ? null : widget.users[_index];

  void _animateTo(Offset target, VoidCallback onEnd) {
    _snapAnim = Tween<Offset>(begin: _drag, end: target).animate(
      CurvedAnimation(parent: _snap, curve: Curves.easeOut),
    );
    _snap.forward(from: 0).whenComplete(() {
      _snap.reset();
      _drag = Offset.zero;
      onEnd();
    });
  }

  Future<void> _dismissRight() async {
    final u = _top;
    if (u == null) return;
    _animateTo(const Offset(420, 0), () async {
      await widget.onLike(u);
      if (mounted) setState(() => _index++);
    });
  }

  Future<void> _dismissLeft() async {
    final u = _top;
    if (u == null) return;
    _animateTo(const Offset(-420, 0), () async {
      await widget.onSkip(u);
      if (mounted) setState(() => _index++);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_snap.isAnimating) return;
    setState(() => _drag += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_snap.isAnimating) return;
    final w = MediaQuery.sizeOf(context).width;
    if (_drag.dx > w * 0.22) {
      _dismissRight();
      return;
    }
    if (_drag.dx < -w * 0.22) {
      _dismissLeft();
      return;
    }
    _animateTo(Offset.zero, () {});
  }

  @override
  Widget build(BuildContext context) {
    if (_empty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'Keşif destesi bitti — yenileyerek yeni profiller getirin.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final top = _top!;
    final rot = (_drag.dx / 600).clamp(-0.12, 0.12);
    final next = _index + 1 < widget.users.length ? widget.users[_index + 1] : null;

    return Column(
      children: [
        SizedBox(
          height: 420,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (next != null)
                Transform.scale(
                  scale: 0.96,
                  child: Opacity(
                    opacity: 0.55,
                    child: DiscoverySocialUserCard(
                      user: next,
                      onOpenProfile: () => widget.onOpenProfile(next),
                      onLike: () {},
                      onSkip: () {},
                    ),
                  ),
                ),
              Transform.translate(
                offset: _drag,
                child: Transform.rotate(
                  angle: rot * math.pi,
                  child: GestureDetector(
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Stack(
                      children: [
                        DiscoverySocialUserCard(
                          user: top,
                          onOpenProfile: () => widget.onOpenProfile(top),
                          onLike: _dismissRight,
                          onSkip: _dismissLeft,
                          onReport: widget.onReport == null
                              ? null
                              : () => widget.onReport!(top),
                        ),
                        if (_drag.dx.abs() > 12)
                          Positioned(
                            top: 16,
                            left: _drag.dx > 0 ? 16 : null,
                            right: _drag.dx < 0 ? 16 : null,
                            child: _SwipeStamp(like: _drag.dx > 0),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlatformSocialCircleAction(
              icon: Icons.close_rounded,
              tone: PlatformSocialPillTone.danger,
              onTap: _dismissLeft,
            ),
            const SizedBox(width: 28),
            PlatformSocialCircleAction(
              icon: Icons.favorite_rounded,
              tone: PlatformSocialPillTone.accent,
              onTap: _dismissRight,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Sola kaydır: geç · Sağa kaydır: beğen',
          style: TextStyle(
            fontSize: 11,
            color: PlatformSocialPalette.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({required this.like});

  final bool like;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: like ? Colors.greenAccent : Colors.redAccent,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        like ? 'BEĞEN' : 'GEÇ',
        style: TextStyle(
          color: like ? Colors.greenAccent : Colors.redAccent,
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

