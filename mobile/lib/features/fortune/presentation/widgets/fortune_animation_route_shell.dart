import 'package:flutter/material.dart';

import '../../../../core/site_animation/presentation/widgets/site_animation_context_host.dart';

/// Fal alt rotalarında site animasyon bağlamı (`ctx_fal_tarot`).
class FortuneAnimationRouteShell extends StatelessWidget {
  const FortuneAnimationRouteShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SiteAnimationContextHost(
      context: SiteAnimationContext.falTarot,
      child: child,
    );
  }
}
