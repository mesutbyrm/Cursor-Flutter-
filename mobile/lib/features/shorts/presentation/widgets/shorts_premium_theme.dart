import 'package:flutter/material.dart';

import '../../../../core/performance/effects_perf.dart';
import '../../../../core/theme/app_theme_extensions.dart';

/// Kısa video chrome arka planları — AMOLED uyumlu.
abstract final class ShortsPremiumTheme {
  /// Tam ekran video akışı (OLED saf siyah).
  static Color feedBackground(BuildContext context) => Colors.black;

  /// Keşfet / hashtag / stüdyo chrome.
  static Color chromeBackground(BuildContext context) =>
      context.scaffoldBg;

  static BoxDecoration feedTopBarDecoration(BuildContext context) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0.72),
          Colors.black.withValues(alpha: 0.35),
          Colors.transparent,
        ],
        stops: const [0, 0.55, 1],
      ),
    );
  }

  static Widget feedTopBar({
    required BuildContext context,
    required Widget child,
  }) {
    return EffectsPerf.chromeBar(
      context: context,
      sigma: 12,
      decoration: feedTopBarDecoration(context),
      child: child,
    );
  }

  static BorderRadius get tileRadius => BorderRadius.circular(14);

  static BorderRadius get chipRadius => BorderRadius.circular(999);
}
