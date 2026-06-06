import 'package:flutter/material.dart';

import '../../../../../core/ui/premium_2026/liquid_glass.dart';
import '../../../../social/presentation/widgets/instagram/social_stories_rail.dart';

/// Hikâye şeridi — cam çerçeve.
class DiscoverPremiumStories extends StatelessWidget {
  const DiscoverPremiumStories({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: LiquidGlass(
        padding: const EdgeInsets.symmetric(vertical: 8),
        borderRadius: BorderRadius.circular(24),
        blur: 12,
        child: const SocialStoriesRail(),
      ),
    );
  }
}
