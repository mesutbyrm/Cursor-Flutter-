import 'package:flutter/material.dart';

/// Profil açılışında avatar → isim → rozet sıralı fade/slide.
class SiteAnimationProfileEntranceStagger extends StatefulWidget {
  const SiteAnimationProfileEntranceStagger({
    super.key,
    required this.avatar,
    required this.nameRow,
    this.membershipRow,
    this.badgeRow,
  });

  final Widget avatar;
  final Widget nameRow;
  final Widget? membershipRow;
  final Widget? badgeRow;

  @override
  State<SiteAnimationProfileEntranceStagger> createState() =>
      _SiteAnimationProfileEntranceStaggerState();
}

class _SiteAnimationProfileEntranceStaggerState
    extends State<SiteAnimationProfileEntranceStagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _stagger(Widget child, double start, double end) {
    final anim = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stagger(widget.avatar, 0, 0.35),
        const SizedBox(height: 8),
        _stagger(widget.nameRow, 0.2, 0.55),
        if (widget.badgeRow != null) ...[
          const SizedBox(height: 6),
          _stagger(widget.badgeRow!, 0.35, 0.7),
        ],
        if (widget.membershipRow != null) ...[
          const SizedBox(height: 6),
          _stagger(widget.membershipRow!, 0.5, 0.85),
        ],
      ],
    );
  }
}
