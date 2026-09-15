import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/social_discovery_user.dart';
import 'discovery_dating_profile_card.dart';

typedef DiscoverySwipeCallback = Future<void> Function(SocialDiscoveryUser user);

/// Swipe destesi — beğen / geç / süper beğeni / geri al.
class DiscoverySwipeDeck extends StatefulWidget {
  const DiscoverySwipeDeck({
    super.key,
    required this.users,
    required this.onLike,
    required this.onSkip,
    required this.onSuperLike,
    required this.onRewind,
    required this.onOpenProfile,
    this.onReport,
    this.canRewind = false,
    this.canSuperLike = true,
    this.busy = false,
    this.onNeedMore,
  });

  final List<SocialDiscoveryUser> users;
  final DiscoverySwipeCallback onLike;
  final DiscoverySwipeCallback onSkip;
  final DiscoverySwipeCallback onSuperLike;
  final Future<void> Function() onRewind;
  final void Function(SocialDiscoveryUser user) onOpenProfile;
  final void Function(SocialDiscoveryUser user)? onReport;
  final bool canRewind;
  final bool canSuperLike;
  final bool busy;
  final VoidCallback? onNeedMore;

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
      duration: const Duration(milliseconds: 240),
    )..addListener(() {
        if (_snapAnim != null) setState(() => _drag = _snapAnim!.value);
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
      setState(() {
        _index = widget.users.isEmpty ? 0 : widget.users.length - 1;
        _drag = Offset.zero;
      });
    }
    if (widget.users.length - _index <= 3) {
      widget.onNeedMore?.call();
    }
  }

  bool get _empty => _index >= widget.users.length;

  SocialDiscoveryUser? get _top =>
      _empty ? null : widget.users[_index];

  void _animateTo(Offset target, VoidCallback onEnd) {
    _snapAnim = Tween<Offset>(begin: _drag, end: target).animate(
      CurvedAnimation(parent: _snap, curve: Curves.easeOutCubic),
    );
    _snap.forward(from: 0).whenComplete(() {
      _snap.reset();
      _drag = Offset.zero;
      onEnd();
    });
  }

  Future<void> _dismissRight() async {
    if (widget.busy) return;
    final u = _top;
    if (u == null) return;
    _animateTo(Offset(MediaQuery.sizeOf(context).width, _drag.dy), () async {
      await widget.onLike(u);
      if (mounted) setState(() => _index++);
    });
  }

  Future<void> _dismissLeft() async {
    if (widget.busy) return;
    final u = _top;
    if (u == null) return;
    _animateTo(Offset(-MediaQuery.sizeOf(context).width, _drag.dy), () async {
      await widget.onSkip(u);
      if (mounted) setState(() => _index++);
    });
  }

  Future<void> _superLike() async {
    if (widget.busy || !widget.canSuperLike) return;
    final u = _top;
    if (u == null) return;
    _animateTo(Offset(0, -MediaQuery.sizeOf(context).height * 0.4), () async {
      await widget.onSuperLike(u);
      if (mounted) setState(() => _index++);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_snap.isAnimating || widget.busy) return;
    setState(() => _drag += d.delta);
  }

  void _onPanEnd(DragEndDetails d) {
    if (_snap.isAnimating || widget.busy) return;
    final w = MediaQuery.sizeOf(context).width;
    if (_drag.dx > w * 0.22) {
      _dismissRight();
      return;
    }
    if (_drag.dx < -w * 0.22) {
      _dismissLeft();
      return;
    }
    if (_drag.dy < -w * 0.18) {
      _superLike();
      return;
    }
    _animateTo(Offset.zero, () {});
  }

  @override
  Widget build(BuildContext context) {
    if (_empty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: DiscoverEmptyInline(
          icon: Icons.auto_awesome_rounded,
          title: 'Şimdilik yeni profil yok',
          subtitle:
              'Filtreleri gevşetin veya biraz sonra yenileyin. Konum paylaşımı yakındaki profilleri artırır.',
        ),
      );
    }

    final top = _top!;
    final rot = (_drag.dx / 500).clamp(-0.14, 0.14);
    final next =
        _index + 1 < widget.users.length ? widget.users[_index + 1] : null;
    final progress = _drag.dx / MediaQuery.sizeOf(context).width;

    return Column(
      children: [
        SizedBox(
          height: math.min(MediaQuery.sizeOf(context).height * 0.52, 480),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (next != null)
                Transform.scale(
                  scale: 0.94,
                  child: Opacity(
                    opacity: 0.45,
                    child: DiscoveryDatingProfileCard(
                      user: next,
                      onOpenProfile: () => widget.onOpenProfile(next),
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
                    child: DiscoveryDatingProfileCard(
                      user: top,
                      dragProgress: progress,
                      onOpenProfile: () => widget.onOpenProfile(top),
                    ),
                  ),
                ),
              ),
              if (widget.busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black26,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            PlatformSocialCircleAction(
              icon: Icons.replay_rounded,
              onTap: widget.canRewind
                  ? () {
                      widget.onRewind();
                    }
                  : () {},
              tone: PlatformSocialPillTone.neutral,
            ),
            PlatformSocialCircleAction(
              icon: Icons.close_rounded,
              tone: PlatformSocialPillTone.danger,
              onTap: _dismissLeft,
            ),
            PlatformSocialCircleAction(
              icon: Icons.star_rounded,
              tone: PlatformSocialPillTone.gold,
              onTap: widget.canSuperLike ? _superLike : () {},
            ),
            PlatformSocialCircleAction(
              icon: Icons.favorite_rounded,
              tone: PlatformSocialPillTone.accent,
              onTap: _dismissRight,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Sola geç · Sağa beğen · Yukarı süper beğeni',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: PlatformSocialPalette.textMuted,
          ),
        ),
      ],
    );
  }
}

class DiscoverEmptyInline extends StatelessWidget {
  const DiscoverEmptyInline({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 48, color: PlatformSocialPalette.textMuted),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PlatformSocialPalette.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}
