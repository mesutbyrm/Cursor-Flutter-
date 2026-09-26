import 'package:flutter/material.dart';

import '../../../../social/presentation/widgets/stories_strip.dart';
import '../../theme/home_approved_design.dart';

/// Ana sayfa hikâye şeridi.
class StoriesSection extends StatelessWidget {
  const StoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const StoriesStrip(
      ringSize: HomeApprovedDesign.storySize,
      horizontalPadding: HomeApprovedDesign.hPad - 4,
      spacing: 6,
    );
  }
}
