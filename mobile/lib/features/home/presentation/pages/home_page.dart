import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../feed/presentation/widgets/discover_premium_2026/discover_premium_visual.dart';
import '../providers/home_providers.dart';
import '../providers/home_realtime_bridge.dart';
import '../theme/home_palette.dart';
import '../widgets/home_discover_grid.dart';
import '../widgets/home_fan_club_row.dart';
import '../widgets/home_fortune_grid.dart';
import '../widgets/home_gold_memberships_row.dart';
import '../widgets/home_live_fortune_tellers_row.dart';
import '../widgets/home_live_streams_row.dart';
import '../widgets/home_stories_section.dart';
import '../widgets/home_site_top_bar.dart';
import '../widgets/home_trend_videos_row.dart';
import '../widgets/home_voice_rooms_row.dart';

/// canlifal.com ana sayfa — dikey akış, native API, WebView yok.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeRealtimeBridgeProvider).start();
    });
  }

  Future<void> _onRefresh() => refreshHomeData(ref);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: DiscoverPremiumVisual.backgroundBottom,
      body: CosmicGalaxyBackground(
        showVignette: true,
        child: RefreshIndicator(
          color: DiscoverPremiumVisual.primary,
          backgroundColor: HomePalette.darkBackground,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: HomeSiteTopBar()),
              const SliverToBoxAdapter(child: HomeStoriesSection()),
              const SliverToBoxAdapter(child: HomeLiveStreamsRow()),
              const SliverToBoxAdapter(child: HomeVoiceRoomsRow()),
              const SliverToBoxAdapter(child: HomeLiveFortuneTellersRow()),
              const SliverToBoxAdapter(child: HomeFortuneGrid()),
              const SliverToBoxAdapter(child: HomeTrendVideosRow()),
              const SliverToBoxAdapter(child: HomeDiscoverGrid()),
              const SliverToBoxAdapter(child: HomeFanClubRow()),
              const SliverToBoxAdapter(child: HomeGoldMembershipsRow()),
              SliverToBoxAdapter(child: SizedBox(height: 96 + bottom)),
            ],
          ),
        ),
      ),
    );
  }
}
