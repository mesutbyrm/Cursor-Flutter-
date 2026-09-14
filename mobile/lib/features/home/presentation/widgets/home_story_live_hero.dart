import 'package:flutter/material.dart';

import 'approved/live_broadcast_section.dart';
import 'approved/stories_section.dart';

/// Story + canlı yayın — tek görsel blok (daha az section gürültüsü).
class HomeStoryLiveHero extends StatelessWidget {
  const HomeStoryLiveHero({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StoriesSection(),
        LiveBroadcastSection(),
      ],
    );
  }
}
