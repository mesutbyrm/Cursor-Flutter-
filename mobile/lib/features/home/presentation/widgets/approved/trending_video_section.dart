import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shorts/presentation/widgets/shorts_hub_strip.dart';

/// Ana sayfa — yüklenen kısa videolar (R2/CDN). YouTube trend içeriği gösterilmez.
class TrendingVideoSection extends ConsumerWidget {
  const TrendingVideoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ShortsHubStrip(
      emoji: '🔥',
      title: 'Trend Videolar',
      useHomeHeader: true,
      padding: EdgeInsets.symmetric(horizontal: 0),
    );
  }
}
