import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import '../providers/home_providers.dart';
import '../providers/home_realtime_bridge.dart';
import '../theme/home_approved_design.dart';
import '../widgets/approved/home_horoscope_section.dart';
import '../widgets/approved/home_quick_actions.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/approved/discover_section.dart';
import '../widgets/approved/fan_club_section.dart';
import '../widgets/approved/fortune_section.dart';
import '../widgets/approved/gold_section.dart';
import '../widgets/approved/home_header.dart';
import '../widgets/approved/live_broadcast_section.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychics_home_section.dart';
import '../widgets/approved/more_fortunes_button.dart';
import '../widgets/approved/stories_section.dart';
import '../widgets/approved/trending_video_section.dart';
import '../widgets/home_deferred_section.dart';
import '../widgets/home_game_center_section.dart';
import '../widgets/home_games_row.dart';

/// Onaylı ana sayfa mockup — piksel uyumlu bölüm sırası.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  HomeRealtimeBridge? _realtimeBridge;

  @override
  void initState() {
    super.initState();
    _realtimeBridge = ref.read(homeRealtimeBridgeProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _realtimeBridge?.start();
    });
  }

  @override
  void dispose() {
    // ref kullanılamaz — ConsumerState dispose sırasında Riverpod hata verir.
    _realtimeBridge?.dispose();
    _realtimeBridge = null;
    super.dispose();
  }

  Future<void> _onRefresh() => refreshHomeData(ref);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: context.isDarkTheme
          ? HomeApprovedDesign.background
          : context.colors.scaffoldBackground,
      body: RefreshIndicator(
        color: context.isDarkTheme
            ? HomeApprovedDesign.purple
            : context.colors.primary,
        backgroundColor: context.isDarkTheme
            ? HomeApprovedDesign.surface
            : context.colors.surface,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            const SliverToBoxAdapter(child: HomeHeader()),
            const SliverToBoxAdapter(child: HomeBannerCarousel()),
            const SliverToBoxAdapter(child: HomeQuickActions()),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                child: LiveBroadcastSection(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                delay: Duration(milliseconds: 120),
                child: PsychicsHomeSection(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                delay: Duration(milliseconds: 200),
                child: FortuneSection(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                delay: Duration(milliseconds: 280),
                child: StoriesSection(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                delay: Duration(milliseconds: 360),
                child: HomeHoroscopeSection(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                delay: Duration(milliseconds: 440),
                child: TrendingVideoSection(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                delay: Duration(milliseconds: 520),
                child: DiscoverSection(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                delay: Duration(milliseconds: 600),
                child: FanClubSection(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                delay: Duration(milliseconds: 680),
                child: GoldSection(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                delay: Duration(milliseconds: 760),
                child: HomeGameCenterSection(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                delay: Duration(milliseconds: 840),
                child: HomeGamesRow(),
              ),
            ),
            const SliverToBoxAdapter(
              child: HomeDeferredSection(
                delay: Duration(milliseconds: 900),
                child: MoreFortunesButton(),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 72 + bottom)),
          ],
        ),
      ),
    );
  }
}
