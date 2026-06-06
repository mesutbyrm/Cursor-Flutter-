import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tutarlı çek-yenile: iOS’ta adaptive (Cupertino), renk / stroke / edgeOffset ayarlı.
class SocialRefreshIndicator extends StatelessWidget {
  const SocialRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// AppBar / safe area altında doğru konum (ör. `topPadding + kToolbarHeight`).
  final double? edgeOffset;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return RefreshIndicator.adaptive(
      onRefresh: onRefresh,
      color: AppTheme.accent,
      backgroundColor: AppTheme.surfaceElevated,
      displacement: 48,
      strokeWidth: 2.75,
      edgeOffset: edgeOffset ?? top,
      child: child,
    );
  }
}
