import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/premium_2026/premium_2026.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_refresh.dart';
import '../providers/fortune_api_providers.dart';
import '../widgets/ultra_premium/ultra_fortune_app_bar.dart';
import '../widgets/ultra_premium/ultra_fortune_cosmic_background.dart';
import '../widgets/ultra_premium/ultra_fortune_daily_energy.dart';
import '../widgets/ultra_premium/ultra_fortune_hero_section.dart';
import '../widgets/ultra_premium/ultra_fortune_prophecy_card.dart';
import '../widgets/ultra_premium/ultra_fortune_tokens.dart';
import '../widgets/ultra_premium/ultra_fortune_types_section.dart';

/// Fal & Tarot ana sekme — Ultra Premium 2026 Liquid Glass mistik evren.
class FortuneTarotHubPage extends ConsumerStatefulWidget {
  const FortuneTarotHubPage({super.key});

  @override
  ConsumerState<FortuneTarotHubPage> createState() => _FortuneTarotHubPageState();
}

class _FortuneTarotHubPageState extends ConsumerState<FortuneTarotHubPage> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if ((offset - _scrollOffset).abs() > 0.5) {
      setState(() => _scrollOffset = offset);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(fortuneHistoryProvider);
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final bg = context.isDarkTheme
        ? UltraFortuneTokens.deepNight
        : context.colors.scaffoldBackground;

    return Scaffold(
      backgroundColor: bg,
      body: UltraFortuneCosmicBackground(
        scrollOffset: _scrollOffset,
        child: DiscoverRefresh.wrap(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: PremiumMotion.listPhysics,
            slivers: [
              const SliverToBoxAdapter(child: UltraFortuneAppBar()),
              const SliverToBoxAdapter(child: UltraFortuneHeroSection()),
              const SliverToBoxAdapter(child: UltraFortuneProphecyCard()),
              const SliverToBoxAdapter(child: UltraFortuneTypesSection()),
              const SliverToBoxAdapter(child: UltraFortuneDailyEnergy()),
              SliverToBoxAdapter(child: SizedBox(height: bottom + 100)),
            ],
          ),
        ),
      ),
    );
  }
}
