import 'package:flutter/material.dart';

/// Dar Android ekranları (&lt;360dp) için yardımcılar.
abstract final class CdsResponsive {
  static const double narrowBreakpoint = 360;

  static bool isNarrow(BuildContext context) =>
      MediaQuery.sizeOf(context).width < narrowBreakpoint;

  /// Sabit section height yerine min/max ile esnek kutu.
  static double sectionHeight(
    BuildContext context, {
    required double min,
    required double max,
    double fractionOfWidth = 0.55,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    final h = w * fractionOfWidth;
    return h.clamp(min, max);
  }

  static EdgeInsets screenPadding(BuildContext context) {
    final narrow = isNarrow(context);
    return EdgeInsets.symmetric(
      horizontal: narrow ? 12 : 16,
      vertical: narrow ? 8 : 12,
    );
  }
}
