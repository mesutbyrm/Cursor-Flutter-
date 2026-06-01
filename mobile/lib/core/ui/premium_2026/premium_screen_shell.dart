import 'package:flutter/material.dart';

import 'premium_immersive_background.dart';
import 'premium_motion.dart';

/// Alt sayfalar — immersive arka plan + premium scroll.
class PremiumScreenShell extends StatelessWidget {
  const PremiumScreenShell({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return PremiumImmersiveBackground(
      child: ScrollConfiguration(
        behavior: const _PremiumScrollBehavior(),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

class _PremiumScrollBehavior extends ScrollBehavior {
  const _PremiumScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      PremiumMotion.listPhysics;
}
