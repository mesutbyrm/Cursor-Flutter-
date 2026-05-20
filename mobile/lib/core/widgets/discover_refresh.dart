import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Keşfet ve sekmelerde daha kısa / hızlı hissedilen yenileme.
abstract final class DiscoverRefresh {
  static const displacement = 28.0;
  static const strokeWidth = 2.0;
  static const color = AppColors.accentPink;
  static const backgroundColor = AppColors.bgPurpleGlow;

  static RefreshIndicator wrap({
    required Future<void> Function() onRefresh,
    required Widget child,
  }) {
    return RefreshIndicator(
      color: color,
      backgroundColor: backgroundColor,
      displacement: displacement,
      strokeWidth: strokeWidth,
      onRefresh: onRefresh,
      child: child,
    );
  }
}
