import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/discover/discover_live_carousel.dart';

/// Canlı yayın paneli.
class DiscoverPremiumLivePanel extends ConsumerWidget {
  const DiscoverPremiumLivePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DiscoverLiveCarousel();
  }
}

/// Trend sekmesi — canlı yayın özeti.
class DiscoverPremiumTrendPanel extends ConsumerWidget {
  const DiscoverPremiumTrendPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DiscoverLiveCarousel();
  }
}
