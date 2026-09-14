import 'package:flutter/material.dart';

import 'cds_colors.dart';

/// CDS gölge katmanları.
abstract final class CdsShadows {
  static const List<BoxShadow> elevation0 = [];

  static List<BoxShadow> elevation1(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.08,
          ),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> elevation2(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.45 : 0.12,
          ),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> effectGold(BuildContext context) => [
        BoxShadow(
          color: CdsColors.gold.withValues(alpha: 0.35),
          blurRadius: 22,
          spreadRadius: 0,
        ),
      ];
}
