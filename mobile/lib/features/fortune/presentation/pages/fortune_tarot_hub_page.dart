import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/push/push_notification_service.dart';
import '../../../../core/site_animation/presentation/widgets/site_animation_context_host.dart';
import '../../../../core/ui/premium_2026/premium_2026.dart';
import '../../../../core/widgets/discover_refresh.dart';
import '../../../bana_ozel/presentation/providers/bana_ozel_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../live_psychics/presentation/providers/live_psychics_providers.dart';
import '../design/fortune_lane_theme.dart';
import '../providers/fortune_api_providers.dart';
import '../providers/fortune_hub_providers.dart';
import '../providers/fortune_types_display_provider.dart';
import '../widgets/fortune_hub_2026/fortune_hub_kit.dart';
import '../widgets/fortune_hub_2026/fortune_hub_live_sections.dart';
import '../widgets/fortune_hub_2026/fortune_hub_sections.dart';
import '../widgets/fortune_hub_2026/fortune_hub_top.dart';
import '../widgets/fortune_zodiac_hub_card.dart' show maybePromptFortuneBirthOnHub;

/// Fal & Tarot ana sekme — Premium 2026 (tek tasarım sistemi, gerçek API verisi).
class FortuneTarotHubPage extends ConsumerStatefulWidget {
  const FortuneTarotHubPage({super.key, this.initialTypeSlug});

  /// Derin bağlantı: `/fortune?type=tarot`
  final String? initialTypeSlug;

  @override
  ConsumerState<FortuneTarotHubPage> createState() =>
      _FortuneTarotHubPageState();
}

class _FortuneTarotHubPageState extends ConsumerState<FortuneTarotHubPage> {
  final _scrollController = ScrollController();
  var _deepLinkHandled = false;

  @override
  void initState() {
    super.initState();
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
        await PushNotificationService.instance.setDailyFortuneReminderEnabled(
          true,
        );
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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(fortuneHistoryProvider);
    ref.invalidate(fortuneDailyInsightsProvider);
    ref.invalidate(fortuneHubPreferencesStoreProvider);
    ref.invalidate(banaOzelCatalogProvider);
    ref.invalidate(homeOnlinePsychicsProvider);
    ref.invalidate(homeTrendVideosProvider);
    invalidateFortuneTypesDisplay(ref);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return FortuneLaneTheme(
      child: SiteAnimationContextHost(
        context: SiteAnimationContext.falTarot,
        child: Scaffold(
          backgroundColor: FortuneUi.bg0,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: FortuneUi.backgroundGradient,
            ),
            child: DiscoverRefresh.wrap(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                physics: PremiumMotion.listPhysics,
                slivers: [
                  // SliverList: alt bölümler yalnızca görünür olunca kurulur
                  // ve kendi verilerini o zaman ister (tembel yükleme).
                  SliverList(
                    delegate: SliverChildListDelegate([
                      const FortuneHubHeader(),
                      const FortuneWalletBar(),
                      const FortuneHubHero(),
                      const FortuneHubStatRow(),
                      const FortuneHubHistoryBanner(),
                      const FortuneHubSearchField(),
                      const FortuneHubQuickGrid(),
                      const FortuneHubDailyProphecy(),
                      const FortuneHubRecentReadings(),
                      const FortuneHubPopularTypes(),
                      const FortuneHubForYouBanner(),
                      const FortuneHubAllTypes(),
                      const FortuneHubPsychics(),
                      const FortuneHubShorts(),
                      const FortuneHubReadyReadings(),
                      const FortuneHubBanaOzel(),
                      const FortuneHubReminderTile(),
                      const FortuneHubExploreBanner(),
                      SizedBox(height: bottom + 100),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
