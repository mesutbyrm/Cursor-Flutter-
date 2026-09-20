import 'package:flutter/material.dart';

import '../../features/shell/presentation/app_bottom_nav_host.dart';

/// [AppBottomNavHost] alt çubuğu görünürken içerik/composer için alt boşluk.
abstract final class OverlayBottomNavInset {
  static const double _barContentHeight = 56 + 8 + 6;

  static bool showsForPath(String location) =>
      AppBottomNavHost.shouldShowBottomNav(location);

  static double forPath(BuildContext context, String location) {
    final safe = MediaQuery.paddingOf(context).bottom;
    if (!showsForPath(location)) return safe + 12;
    return _barContentHeight + safe + 8;
  }
}
