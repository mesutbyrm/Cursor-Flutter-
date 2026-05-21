import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover/discover_icon_button.dart';
import '../data/fortune_catalog.dart';
import '../widgets/fortune_daily_card.dart';
import '../widgets/fortune_glass_card.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_premium_upsell.dart';
import '../widgets/fortune_type_grid_card.dart';

/// Fal & Tarot ana sayfa — mockup: grid, günlük fal, premium, özellikler.
class FortuneTarotHubPage extends StatelessWidget {
  const FortuneTarotHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FortuneMysticBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(8, top + 4, 12, 0),
                child: Row(
                  children: [
                    DiscoverIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(child: _HeroSection()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final type = FortuneCatalog.types[i];
                    return FortuneTypeGridCard(
                      type: type,
                      onExplore: () => context.push('/fortune/${type.slug}'),
                    );
                  },
                  childCount: FortuneCatalog.types.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: FortuneDailyCard(
                  type: FortuneCatalog.dailyFortune,
                  onOpen: () => context.push(
                    '/fortune/${FortuneCatalog.dailyFortune.slug}',
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: const FortunePremiumUpsell(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                child: _DesignFeaturesBlock(),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) =>
                          AppColors.brandGradient.createShader(b),
                      child: const Text(
                        'Fal & Tarot',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      FortuneCatalog.tagline,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    for (final b in FortuneCatalog.introBullets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: AppColors.accentPink.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CrystalBallHero(),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrystalBallHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accentPurple.withValues(alpha: 0.7),
                  AppColors.accentCyan.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
              boxShadow: AppColors.glowShadow(AppColors.accentPurple, blur: 28),
            ),
          ),
          const Text('🔮', style: TextStyle(fontSize: 48)),
          const Positioned(
            bottom: 0,
            child: Text('🕯️', style: TextStyle(fontSize: 18)),
          ),
          const Positioned(
            top: 8,
            right: 4,
            child: Text('🃏', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class _DesignFeaturesBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FortuneGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TASARIM ÖZELLİKLERİ',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1.2,
              color: AppColors.accentCyan,
            ),
          ),
          const SizedBox(height: 12),
          for (final f in FortuneCatalog.designFeatures)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: AppColors.accentPink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
