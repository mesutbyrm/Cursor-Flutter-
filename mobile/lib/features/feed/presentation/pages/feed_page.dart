import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_refresh.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../providers/feed_providers.dart';
import '../providers/platform_stats_providers.dart';
import '../widgets/discover_premium_2026/discover_premium_feed.dart';

/// Keşfet ana sayfa — Premium 2026 (PART 2).
class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  Future<void> _refresh() async {
    await Future.wait([
      ref.refresh(liveStreamsProvider.future),
      ref.refresh(voiceRoomsProvider.future),
      ref.refresh(socialStoryRingsProvider.future),
      ref.refresh(platformStatsProvider.future),
      ref.read(feedNotifierProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverPremiumFeed(onRefresh: _refresh),
    );
  }
}
