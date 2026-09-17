import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/cds_fx.dart';
import '../../../../core/navigation/unread_badge_format.dart';
import '../../../../core/motion/canlifal_motion_tokens.dart';
import '../../../../core/motion/canlifal_motion_widgets.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../theme/home_approved_design.dart';

bool _homeMotionEnabled(BuildContext context, WidgetRef ref) {
  if (MediaQuery.disableAnimationsOf(context)) return false;
  return !ref.watch(cdsFxProvider).decorativeDisabled;
}

/// CANLI rozeti — hafif nefes pulse (performans modunda statik).
class HomePulsingLiveBadge extends ConsumerStatefulWidget {
  const HomePulsingLiveBadge({super.key, this.compact = false});

  final bool compact;

  @override
  ConsumerState<HomePulsingLiveBadge> createState() =>
      _HomePulsingLiveBadgeState();
}

class _HomePulsingLiveBadgeState extends ConsumerState<HomePulsingLiveBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = _homeMotionEnabled(context, ref);
    if (on && _c == null) {
      _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    } else if (!on && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badge = LiveBadge(compact: widget.compact);
    final ctrl = _c;
    if (ctrl == null) return badge;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, child) {
        final t = 0.96 + ctrl.value * 0.06;
        return Transform.scale(scale: t, child: child);
      },
      child: badge,
    );
  }
}

/// Story halkası — mor/pembe gradient + hafif glow nefesi.
class HomeStoryRingPulse extends ConsumerStatefulWidget {
  const HomeStoryRingPulse({
    super.key,
    required this.child,
    this.active = true,
  });

  final Widget child;
  final bool active;

  @override
  ConsumerState<HomeStoryRingPulse> createState() => _HomeStoryRingPulseState();
}

class _HomeStoryRingPulseState extends ConsumerState<HomeStoryRingPulse>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = widget.active && _homeMotionEnabled(context, ref);
    if (on && _c == null) {
      _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2200),
      )..repeat(reverse: true);
    } else if (!on && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = HomeApprovedDesign.storySize + 4;
    final ctrl = _c;
    return AnimatedBuilder(
      animation: ctrl ?? const AlwaysStoppedAnimation(0),
      builder: (context, _) {
        final t = ctrl?.value ?? 0;
        final glow = 6.0 + t * 8;
        final alpha = 0.18 + t * 0.22;
        return Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: widget.active
                ? HomeApprovedDesign.storyRingGradient
                : null,
            border: widget.active
                ? null
                : Border.all(color: HomeApprovedDesign.border, width: 2),
            boxShadow: widget.active && ctrl != null
                ? [
                    BoxShadow(
                      color: HomeApprovedDesign.pink.withValues(alpha: alpha),
                      blurRadius: glow,
                      spreadRadius: t * 0.8,
                    ),
                  ]
                : null,
          ),
          child: ClipOval(child: widget.child),
        );
      },
    );
  }
}

/// Bildirim/mesaj rozeti — yeni sayıda kısa pulse.
class HomePulsingIconBadge extends ConsumerStatefulWidget {
  const HomePulsingIconBadge({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  @override
  ConsumerState<HomePulsingIconBadge> createState() =>
      _HomePulsingIconBadgeState();
}

class _HomePulsingIconBadgeState extends ConsumerState<HomePulsingIconBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  var _lastBadge = 0;

  @override
  void initState() {
    super.initState();
    _lastBadge = widget.badge;
    _c = AnimationController(
      vsync: this,
      duration: CanlifalMotionTokens.microMax,
    );
  }

  @override
  void didUpdateWidget(covariant HomePulsingIconBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.badge > _lastBadge && widget.badge > 0) {
      _lastBadge = widget.badge;
      if (_homeMotionEnabled(context, ref)) {
        _c.forward(from: 0);
      }
    } else {
      _lastBadge = widget.badge;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(widget.icon, size: 24, color: HomeApprovedDesign.textPrimary),
          if (widget.badge > 0)
            Positioned(
              right: -5,
              top: -4,
              child: ScaleTransition(
                scale: TweenSequence<double>([
                  TweenSequenceItem(
                    tween: Tween(begin: 1.0, end: 1.22),
                    weight: 50,
                  ),
                  TweenSequenceItem(
                    tween: Tween(begin: 1.22, end: 1.0),
                    weight: 50,
                  ),
                ]).animate(
                  CurvedAnimation(parent: _c, curve: CanlifalMotionTokens.spring),
                ),
                child: _BadgeDot(count: widget.badge),
              ),
            ),
        ],
      ),
    );
  }
}

class _BadgeDot extends StatelessWidget {
  const _BadgeDot({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: HomeApprovedDesign.liveRed,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: HomeApprovedDesign.liveRed.withValues(alpha: 0.45),
            blurRadius: 6,
          ),
        ],
      ),
      child: Text(
        UnreadBadgeFormat.label(count),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Scroll’da ilk görünümde tek seferlik fade+slide.
class HomeSectionReveal extends StatefulWidget {
  const HomeSectionReveal({super.key, required this.child});

  final Widget child;

  @override
  State<HomeSectionReveal> createState() => _HomeSectionRevealState();
}

class _HomeSectionRevealState extends State<HomeSectionReveal> {
  final _key = GlobalKey();
  ScrollPosition? _position;
  var _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos == _position) return;
    _position?.removeListener(_check);
    _position = pos;
    _position?.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (_revealed || !mounted) return;
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final h = MediaQuery.sizeOf(context).height;
    if (top < h * 0.92) {
      setState(() => _revealed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (_revealed) {
      return CanlifalEntranceFadeSlide(
        delay: Duration.zero,
        slideY: 0.03,
        child: child,
      );
    }
    return SizedBox(key: _key, child: child);
  }
}

/// Gold hızlı erişim — yavaş shimmer geçişi.
class HomeGoldShimmerBand extends ConsumerStatefulWidget {
  const HomeGoldShimmerBand({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HomeGoldShimmerBand> createState() =>
      _HomeGoldShimmerBandState();
}

class _HomeGoldShimmerBandState extends ConsumerState<HomeGoldShimmerBand>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = _homeMotionEnabled(context, ref);
    if (on && _c == null) {
      _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3200),
      )..repeat();
    } else if (!on && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _c;
    if (ctrl == null) return widget.child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: ctrl,
              builder: (context, _) {
                final t = ctrl.value;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      HomeApprovedDesign.cardRadius,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment(-1.2 + t * 2.4, 0),
                      end: Alignment(-0.2 + t * 2.4, 0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.14),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
