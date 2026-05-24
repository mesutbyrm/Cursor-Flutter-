import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_refresh.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../providers/feed_providers.dart';
import '../widgets/discover/discover_background.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../providers/platform_stats_providers.dart';
import '../widgets/discover/discover_fortune_tarot.dart';
import '../widgets/discover/discover_header.dart';
import '../widgets/discover/discover_live_carousel.dart';
import '../widgets/discover/discover_platform_stats.dart';
import '../widgets/discover/discover_quick_actions.dart';
import '../widgets/discover/discover_voice_orbs.dart';
import '../../../social/presentation/widgets/instagram/social_stories_rail.dart';

/// Keşfet ana sayfa — premium discover layout.
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
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: DiscoverRefresh.wrap(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverSafeArea(
                top: true,
                bottom: false,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const RepaintBoundary(child: DiscoverHeader()),
                    const RepaintBoundary(child: SocialStoriesRail()),
                    const RepaintBoundary(child: DiscoverLiveCarousel()),
                    const RepaintBoundary(child: DiscoverQuickActions()),
                    const RepaintBoundary(child: DiscoverFortuneTarot()),
                    const RepaintBoundary(child: DiscoverPlatformStats()),
                    const RepaintBoundary(child: DiscoverVoiceOrbs()),
                    SizedBox(height: bottom + 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
