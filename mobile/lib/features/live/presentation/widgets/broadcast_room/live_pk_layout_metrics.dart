import 'package:flutter/material.dart';

/// PK immersive — video katmanı ve alt kontroller arasında paylaşılan ölçüler.
abstract final class LivePkLayoutMetrics {
  static const controlBarHeight = 96.0;
  static const inputBarHeight = 48.0;
  static const scoreBandHeight = 86.0;

  /// Referans mock — sol alt sohbet (TikTok/Bigo); ekranla ölçeklenmez.
  static const chatOverlayWidthFactor = 0.56;
  static const chatOverlayHeight = 118.0;
  static const chatOverlayLeftPadding = 8.0;

  static double bottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  static double chromeReserve(BuildContext context) =>
      controlBarHeight + inputBarHeight + bottomInset(context);

  static double videoBottomInset(BuildContext context) =>
      chromeReserve(context) + scoreBandHeight;

  static double headerHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top + 56;
}
