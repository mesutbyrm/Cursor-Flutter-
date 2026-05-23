import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// TikTok / Instagram / iOS tarzı kaydırma: elastik overscroll (bouncing),
/// kısa içerikte de çekilebilir liste (`AlwaysScrollableScrollPhysics`),
/// fare / trackpad / kalem sürüklemesi.
class ModernSocialScrollBehavior extends MaterialScrollBehavior {
  const ModernSocialScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.mouse,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
