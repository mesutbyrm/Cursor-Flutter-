import 'package:flutter/material.dart';

import '../../../../core/site_animation/presentation/widgets/site_animation_context_host.dart';
import '../design/fortune_lane_theme.dart';

/// Fal alt rotalarında site animasyon bağlamı (`ctx_fal_tarot`) + koyu fal teması.
class FortuneAnimationRouteShell extends StatelessWidget {
  const FortuneAnimationRouteShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FortuneLaneTheme(
      child: SiteAnimationContextHost(
        context: SiteAnimationContext.falTarot,
        child: child,
      ),
    );
  }
}
