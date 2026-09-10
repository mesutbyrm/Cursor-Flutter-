import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/bootstrap/startup_perf.dart';
import '../../../../core/performance/lazy_screen_section.dart';
import '../../../../core/push/push_notification_service.dart';
import '../../../../core/ui/premium_2026/premium_2026.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_refresh.dart';
import '../../../../core/site_animation/presentation/widgets/site_animation_context_host.dart';
import '../providers/fortune_api_providers.dart';
import '../providers/fortune_hub_providers.dart';
import '../providers/fortune_types_display_provider.dart';
import '../../../bana_ozel/presentation/providers/bana_ozel_providers.dart';
import '../../../live_psychics/presentation/widgets/psychics_home_section.dart';
import '../widgets/ultra_premium/ultra_fortune_app_bar.dart';
import '../widgets/ultra_premium/ultra_fortune_cosmic_background.dart';
import '../widgets/ultra_premium/ultra_fortune_daily_energy.dart';
import '../widgets/ultra_premium/ultra_fortune_daily_missions_strip.dart';
import '../widgets/ultra_premium/ultra_fortune_hero_section.dart';
import '../widgets/ultra_premium/ultra_fortune_history_strip.dart';
import '../widgets/ultra_premium/ultra_fortune_hub_search_bar.dart';
import '../widgets/ultra_premium/ultra_fortune_prophecy_card.dart';
import '../widgets/ultra_premium/ultra_fortune_ready_readings_strip.dart';
import '../widgets/ultra_premium/ultra_fortune_recommendations_section.dart';
import '../widgets/fortune_zodiac_hub_card.dart';
import '../widgets/ultra_premium/ultra_fortune_tokens.dart';
import '../widgets/ultra_premium/ultra_fortune_quick_actions.dart';
import '../widgets/ultra_premium/ultra_fortune_hub_quick_grid.dart';
import '../widgets/ultra_premium/ultra_fortune_section_placeholder.dart';
import '../widgets/ultra_premium/ultra_fortune_types_section.dart';
import '../../../bana_ozel/presentation/widgets/bana_ozel_hub_section.dart';
import '../../../shorts/presentation/widgets/shorts_hub_strip.dart';

/// Fal & Tarot ana sekme — Ultra Premium 2026 Liquid Glass mistik evren.
class FortuneTarotHubPage extends ConsumerStatefulWidget {
  const FortuneTarotHubPage({super.key, this.initialTypeSlug});

  /// Derin bağlantı: `/fortune?type=tarot`
  final String? initialTypeSlug;

  @override
  ConsumerState<FortuneTarotHubPage> createState() => _FortuneTarotHubPageState();
}

class _FortuneTarotHubPageState extends ConsumerState<FortuneTarotHubPage> {
  final _scrollController = ScrollController();
  final _scrollParallax = ScrollParallaxNotifier();
  var _deepLinkHandled = false;

  @override
  void initState() {
    super.initState();
    _scrollParallax.bind(_scrollController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybePromptFortuneBirthOnHub(context, ref);
      _syncDailyReminder();
      _handleDeepLink();
    });
  }

  Future<void> _syncDailyReminder() async {
    try {
      final store = await ref.read(fortuneHubPreferencesStoreProvider.future);
      if (store.dailyReminderEnabled) {
        await PushNotificationService.instance
            .setDailyFortuneReminderEnabled(true);
      }
    } catch (_) {}
  }

  void _handleDeepLink() {
    if (_deepLinkHandled) return;
    final slug = widget.initialTypeSlug?.trim();
    if (slug == null || slug.isEmpty) return;
    _deepLinkHandled = true;
    context.push('/fortune/$slug');
  }

  @override
  void dispose() {
    _scrollParallax.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(fortuneHistoryProvider);
    ref.invalidate(fortuneDailyInsightsProvider);
    ref.invalidate(fortuneHubPreferencesStoreProvider);
    ref.invalidate(banaOzelCatalogProvider);
    invalidateFortuneTypesDisplay(ref);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final bg = context.isDarkTheme
        ? UltraFortuneTokens.deepNight
        : context.colors.scaffoldBackground;

    return SiteAnimationContextHost(
      context: SiteAnimationContext.falTarot,
      child: Scaffold(
      backgroundColor: bg,
      body: UltraFortuneCosmicBackground(
        scrollParallax: _scrollParallax,
        child: DiscoverRefresh.wrap(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: PremiumMotion.listPhysics,
            slivers: [
              const SliverToBoxAdapter(child: UltraFortuneAppBar()),
              const SliverToBoxAdapter(child: UltraFortuneHeroSection()),
              const SliverToBoxAdapter(child: UltraFortuneLastFortuneCta()),
              const SliverToBoxAdapter(child: UltraFortuneHubSearchBar()),
              const SliverToBoxAdapter(child: UltraFortuneQuickActions()),
              const SliverToBoxAdapter(child: UltraFortuneHistoryStrip()),
              const SliverToBoxAdapter(child: UltraFortuneHubQuickGrid()),
              const SliverToBoxAdapter(child: UltraFortuneTypesSection()),
              const SliverToBoxAdapter(child: UltraFortuneDailyMissionsStrip()),
              const SliverToBoxAdapter(child: UltraFortuneReadyReadingsStrip()),
              const SliverToBoxAdapter(
                child: LazyScreenSection(
                  delay: LazyLoadPerf.fortuneProphecy,
                  repaintIsolate: false,
                  placeholder: const UltraFortuneSectionPlaceholder(height: 140),
                  child: UltraFortuneRecommendationsSection(),
                ),
              ),
              const SliverToBoxAdapter(
                child: LazyScreenSection(
                  delay: LazyLoadPerf.fortuneProphecy,
                  repaintIsolate: false,
                  placeholder: const UltraFortuneSectionPlaceholder(height: 160),
                  child: PsychicsHomeSection(),
                ),
              ),
              const SliverToBoxAdapter(
                child: ShortsHubStrip(
                  title: 'Kısa Videolar',
                  emoji: '🎬',
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                ),
              ),
              const SliverToBoxAdapter(
                child: LazyScreenSection(
                  delay: LazyLoadPerf.fortuneProphecy,
                  repaintIsolate: false,
                  placeholder: const UltraFortuneSectionPlaceholder(height: 120),
                  child: BanaOzelHubSection(),
                ),
              ),
              const SliverToBoxAdapter(child: FortuneZodiacHubCard()),
              const SliverToBoxAdapter(
                child: LazyScreenSection(
                  delay: LazyLoadPerf.fortuneProphecy,
                  repaintIsolate: false,
                  placeholder: const UltraFortuneSectionPlaceholder(height: 100),
                  child: UltraFortuneProphecyCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              const SliverToBoxAdapter(
                child: LazyScreenSection(
                  delay: LazyLoadPerf.fortuneDaily,
                  repaintIsolate: false,
                  placeholder: const UltraFortuneSectionPlaceholder(height: 100),
                  child: UltraFortuneDailyEnergy(),
                ),
              ),
              const SliverToBoxAdapter(child: UltraFortuneDailyReminderTile()),
              SliverToBoxAdapter(child: SizedBox(height: bottom + 100)),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
