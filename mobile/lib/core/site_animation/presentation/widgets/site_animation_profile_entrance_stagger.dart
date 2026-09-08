import 'package:flutter/material.dart';

enum SiteAnimationProfileStaggerLayout { vertical, horizontal }

/// Profil açılışında avatar → isim → rozet sıralı fade/slide.
class SiteAnimationProfileEntranceStagger extends StatefulWidget {
  const SiteAnimationProfileEntranceStagger({
    super.key,
    required this.avatar,
    required this.nameRow,
    this.membershipRow,
    this.badgeRow,
    this.layout = SiteAnimationProfileStaggerLayout.vertical,
    this.avatarSpacing = 8,
    this.badgeSpacing = 6,
  });

  final Widget avatar;
  final Widget nameRow;
  final Widget? membershipRow;
  final Widget? badgeRow;
  final SiteAnimationProfileStaggerLayout layout;
  final double avatarSpacing;
  final double badgeSpacing;

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
    if (widget.layout == SiteAnimationProfileStaggerLayout.horizontal) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _stagger(widget.avatar, 0, 0.35),
          SizedBox(width: widget.avatarSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _stagger(widget.nameRow, 0.2, 0.55),
                if (widget.badgeRow != null) ...[
                  SizedBox(height: widget.badgeSpacing),
                  _stagger(widget.badgeRow!, 0.35, 0.7),
                ],
                if (widget.membershipRow != null) ...[
                  SizedBox(height: widget.badgeSpacing),
                  _stagger(widget.membershipRow!, 0.5, 0.85),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stagger(widget.avatar, 0, 0.35),
        SizedBox(height: widget.avatarSpacing),
        _stagger(widget.nameRow, 0.2, 0.55),
        if (widget.badgeRow != null) ...[
          SizedBox(height: widget.badgeSpacing),
          _stagger(widget.badgeRow!, 0.35, 0.7),
        ],
        if (widget.membershipRow != null) ...[
          SizedBox(height: widget.badgeSpacing),
          _stagger(widget.membershipRow!, 0.5, 0.85),
        ],
      ],
    );
  }
}
