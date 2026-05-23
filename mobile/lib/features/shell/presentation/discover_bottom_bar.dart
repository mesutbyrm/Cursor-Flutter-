import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/premium/premium.dart';

/// Alt navigasyon — premium cam bar (performans odaklı, blur yok).
class DiscoverBottomBar extends StatelessWidget {
  const DiscoverBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    return PremiumNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      onFabTap: onFabTap,
      fabIcon: Icons.videocam_rounded,
    );
  }
}

/// Orta FAB — canlı yayın hazırlığı.
void openLiveFromFab(BuildContext context) {
  context.push('/live/prep');
}
