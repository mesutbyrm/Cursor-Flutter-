import 'package:flutter/material.dart';

import '../../../../../core/ui/premium_2026/premium_immersive_background.dart';

/// Keşfet — immersive mesh gradient arka plan (2026).
class DiscoverBackground extends StatelessWidget {
  const DiscoverBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PremiumImmersiveBackground(child: child);
  }
}
