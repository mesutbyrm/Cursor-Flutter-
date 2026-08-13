import 'package:flutter/material.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import 'approved/discover_section.dart';
import 'approved/fan_club_section.dart';
import 'approved/home_celebrities_section.dart';
import 'approved/fortune_section.dart';
import 'approved/gold_section.dart';
import 'approved/home_header.dart';
import 'approved/home_horoscope_section.dart';
import 'approved/home_quick_actions.dart';
import 'approved/live_broadcast_section.dart';
import 'approved/more_fortunes_button.dart';
import 'approved/stories_section.dart';
import 'approved/trending_video_section.dart';
import 'approved/voice_room_section.dart';
import 'home_banner_carousel.dart';
import 'home_blog_recent_section.dart';
import 'home_daily_missions_teaser.dart';
import 'home_deferred_section.dart';
import 'home_games_row.dart';
import 'home_game_center_section.dart';
import 'home_homepage_buttons_row.dart';
import 'home_platform_stats_strip.dart';
import 'home_ticker_strip.dart';
import 'home_trending_topics_section.dart';
import '../../../live_psychics/presentation/widgets/psychics_home_section.dart';

/// Ana sayfa bölümleri — küçük widget'lar, RepaintBoundary ile izole repaint.
abstract final class HomePageSections {
  static List<Widget> slivers({required double bottomInset}) {
    return [
      const SliverToBoxAdapter(child: RepaintBoundary(child: HomeHeader())),
      const SliverToBoxAdapter(child: RepaintBoundary(child: HomeTickerStrip())),
      const SliverToBoxAdapter(
        child: RepaintBoundary(child: HomePlatformStatsStrip()),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeBannerDelay,
          child: HomeBannerCarousel(),
        ),
      ),
      const SliverToBoxAdapter(
        child: RepaintBoundary(child: HomeHomepageButtonsRow()),
      ),
      const SliverToBoxAdapter(
        child: RepaintBoundary(child: HomeQuickActions()),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeTrendingSectionDelay,
          child: TrendingVideoSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeTrendingSectionDelay,
          child: HomeTrendingTopicsSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeStoriesSectionDelay,
          child: StoriesSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeLiveSectionDelay,
          child: LiveBroadcastSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeVoiceSectionDelay,
          child: VoiceRoomSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homePsychicsSectionDelay,
          child: PsychicsHomeSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeFortuneSectionDelay,
          child: FortuneSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeFortuneSectionDelay,
          child: MoreFortunesButton(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeGameSectionDelay,
          child: HomeGamesRow(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeGameSectionDelay,
          child: HomeGameCenterSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeGameSectionDelay,
          child: HomeDailyMissionsTeaser(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeCelebritiesSectionDelay,
          child: HomeCelebritiesSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeFanClubSectionDelay,
          child: FanClubSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeHoroscopeSectionDelay,
          child: HomeHoroscopeSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeDiscoverSectionDelay,
          child: HomeBlogRecentSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeDiscoverSectionDelay,
          child: DiscoverSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeGoldSectionDelay,
          child: GoldSection(),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 72 + bottomInset)),
    ];
  }
}
