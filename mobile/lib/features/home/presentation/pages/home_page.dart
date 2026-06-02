import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../providers/home_providers.dart';
import '../providers/home_realtime_bridge.dart';
import '../theme/home_palette.dart';
import '../widgets/home_advisors_row.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/home_games_row.dart';
import '../widgets/home_header.dart';
import '../widgets/home_live_streams_row.dart';
import '../widgets/home_social_feed_section.dart';
import '../widgets/home_voice_rooms_row.dart';

/// CanlıFal ana sayfa — tüm bölümler REST API + canlı yenileme.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeRealtimeBridgeProvider).start();
    });
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels <
        _scroll.position.maxScrollExtent - 480) {
      return;
    }
    ref.read(homeFeedNotifierProvider.notifier).loadMore();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() => refreshHomeData(ref);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: HomePalette.darkBackground,
      body: CosmicGalaxyBackground(
        showVignette: true,
        child: RefreshIndicator(
          color: HomePalette.primary,
          backgroundColor: HomePalette.darkBackground,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: HomeHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(child: HomeBannerCarousel()),
              const SliverToBoxAdapter(child: HomeAdvisorsRow()),
              const SliverToBoxAdapter(child: HomeLiveStreamsRow()),
              const SliverToBoxAdapter(child: HomeVoiceRoomsRow()),
              const SliverToBoxAdapter(child: HomeSocialFeedSection()),
              const SliverToBoxAdapter(child: HomeGamesRow()),
              SliverToBoxAdapter(child: SizedBox(height: 88 + bottom)),
            ],
          ),
        ),
      ),
    );
  }
}
