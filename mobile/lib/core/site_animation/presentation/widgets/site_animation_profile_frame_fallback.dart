import 'package:flutter/material.dart';

import 'site_animation_profile_frame_painter.dart';
import '../../domain/site_animation_tier.dart';

/// Lottie yoksa animasyonlu gradient halka fallback.
class SiteAnimationProfileFrameFallback extends StatefulWidget {
  const SiteAnimationProfileFrameFallback({
    super.key,
    required this.tier,
    required this.size,
    this.animationId,
  });

  final SiteAnimationTier tier;
  final double size;
  final String? animationId;

  @override
  State<SiteAnimationProfileFrameFallback> createState() =>
      _SiteAnimationProfileFrameFallbackState();
}

class _SiteAnimationProfileFrameFallbackState
    extends State<SiteAnimationProfileFrameFallback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: SiteAnimationProfileFramePainter(
            animationId: widget.animationId,
            tier: widget.tier,
            phase: _ctrl.value,
          ),
        );
      },
    );
  }
}
