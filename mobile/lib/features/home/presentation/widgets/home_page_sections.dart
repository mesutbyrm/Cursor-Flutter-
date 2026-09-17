import 'package:flutter/material.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import 'approved/home_become_broadcaster_banner.dart';
import 'approved/home_category_chips.dart';
import 'approved/home_header.dart';
import 'approved/home_horoscope_section.dart';
import 'approved/home_popular_broadcasters_section.dart';
import 'approved/home_ref_quick_access.dart';
import 'approved/live_broadcast_section.dart';
import 'approved/more_fortunes_button.dart';
import 'approved/stories_section.dart';
import 'approved/voice_room_section.dart';
import 'home_banner_carousel.dart';
import 'home_deferred_section.dart';
import 'home_discover_premium_banner.dart';
import 'home_fortune_request_types_section.dart';
import 'home_games_section.dart';
import 'home_growth_teasers_section.dart';
import 'home_online_fal_section.dart';
import 'home_promo_popup_banner.dart';
import 'home_viewport_section.dart';
import 'home_advisors_row.dart';
import '../../../bana_ozel/presentation/widgets/home_bana_ozel_section.dart';
import '../../../live_psychics/presentation/widgets/psychics_home_section.dart';
import 'approved/fortune_section.dart';
import 'approved/gold_section.dart';
import 'approved/trending_video_section.dart';

/// Ana sayfa — referans mockup sırası (canlı/sesli öncelik, fal altta).
///
/// Tam envanter: `docs/HOME_PAGE_SECTIONS.md`
abstract final class HomePageSections {
  static List<Widget> slivers({required double bottomInset}) {
    return [
      // Aşama 1 — header + arama
      const SliverToBoxAdapter(child: RepaintBoundary(child: HomeHeader())),
      const SliverToBoxAdapter(child: SizedBox(height: 6)),
      const SliverToBoxAdapter(child: HomeCategoryChips()),
      const SliverToBoxAdapter(child: SizedBox(height: 10)),
      // Hero
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeBannerDelay,
          child: HomeBannerCarousel(),
        ),
      ),
      const SliverToBoxAdapter(child: HomeRefQuickAccess()),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeStoriesSectionDelay,
          child: StoriesSection(),
        ),
      ),
      // Aşama 2 — canlı + sesli (öncelik)
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeStoriesSectionDelay,
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
          delay: StartupPerf.homeTrendingSectionDelay,
          child: HomePopularBroadcastersSection(),
        ),
      ),
      const SliverToBoxAdapter(child: HomeBecomeBroadcasterBanner()),
      // Aşama 3 — trend + tanış
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeTrendingSectionDelay,
          child: TrendingVideoSection(),
        ),
      ),
      const SliverToBoxAdapter(child: HomeDiscoverPremiumBanner()),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeBannerDelay,
          child: HomePromoPopupBanner(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeGameSectionDelay,
          child: HomeGrowthTeasersSection(),
        ),
      ),
      // Aşama 5 — fal & falcılar (alt bölüm)
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeFortuneSectionDelay,
          child: FortuneSection(),
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
          delay: StartupPerf.homePsychicsSectionDelay,
          child: HomeAdvisorsRow(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeFortuneSectionDelay,
          child: HomeBanaOzelSection(),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeFortuneSectionDelay,
          child: HomeFortuneRequestTypesSection(),
        ),
      ),
      SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeFortuneSectionDelay,
          child: HomeViewportSection(
            estimatedHeight: 140,
            child: HomeOnlineFalSection(),
          ),
        ),
      ),
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeFortuneSectionDelay,
          child: MoreFortunesButton(),
        ),
      ),
      // Aşama 6 — gold + oyun + burç
      const SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeFortuneSectionDelay,
          child: GoldSection(),
        ),
      ),
      SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeGameSectionDelay,
          child: HomeViewportSection(
            estimatedHeight: 280,
            child: HomeGamesSection(),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: HomeDeferredSection(
          delay: StartupPerf.homeHoroscopeSectionDelay,
          child: HomeViewportSection(
            estimatedHeight: 160,
            child: HomeHoroscopeSection(),
          ),
        ),
      ),
      SliverToBoxAdapter(child: SizedBox(height: 72 + bottomInset)),
    ];
  }
}
