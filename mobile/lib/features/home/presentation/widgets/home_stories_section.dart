import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../social/presentation/widgets/instagram/social_stories_rail.dart';
import 'home_section_header.dart';

/// Hikâyeler — site ile aynı konum.
class HomeStoriesSection extends ConsumerWidget {
  const HomeStoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Hikâyeler',
          leadingDotColor: Color(0xFF25F4EE),
        ),
        SocialStoriesRail(),
      ],
    );
  }
}
