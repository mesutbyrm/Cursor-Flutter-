import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/premium_2026/premium_2026.dart';
import '../../../../core/widgets/discover_refresh.dart';
import '../widgets/fortune_glass_card.dart';
import '../widgets/fortune_hub_app_bar.dart';
import '../widgets/fortune_hub_daily_energy.dart';
import '../widgets/fortune_hub_hero_banner.dart';
import '../widgets/fortune_mystic_background.dart';
import '../data/fortune_catalog.dart';
import '../widgets/fortune_hub_type_card.dart';

/// Fal & Tarot ana sekme — mockup: enerji, türler, son fallar, AI, premium.
class FortuneTarotHubPage extends ConsumerWidget {
  const FortuneTarotHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FortuneMysticBackground(
        child: DiscoverRefresh.wrap(
          onRefresh: () async {},
          child: CustomScrollView(
            physics: PremiumMotion.listPhysics,
            slivers: [
              const SliverToBoxAdapter(child: FortuneHubAppBar()),
              const SliverToBoxAdapter(child: FortuneHubHeroBanner()),
              const SliverToBoxAdapter(child: FortuneHubDailyEnergy()),
              SliverToBoxAdapter(child: _FortuneTypesHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final entry = FortuneCatalog.hubFortuneTypes[i];
                      final slug = entry.type.slug;
                      return FortuneHubTypeCard(
                        type: entry.type,
                        subtitle: entry.subtitle,
                        onTap: () => context.push('/fortune/$slug'),
                      );
                    },
                    childCount: FortuneCatalog.hubFortuneTypes.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _RecentReadingsSection()),
              SliverToBoxAdapter(child: _AiSuggestionBanner()),
              SliverToBoxAdapter(child: _PremiumBanner()),
              SliverToBoxAdapter(child: SizedBox(height: bottom + 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FortuneTypesHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: _SectionTitleRow(
        title: 'FAL TÜRLERİ',
        seeAllLabel: 'Tüm Fal Türleri >',
        onSeeAll: () => context.push('/fortune/types'),
      ),
    );
  }
}

class _RecentReadingsSection extends StatelessWidget {
  static const _items = [
    _RecentItem('🃏', 'Yeni Başlangıç', 'Tarot', '12 Mar'),
    _RecentItem('💜', 'Kalp Bağı', 'Aşk Falı', '10 Mar'),
    _RecentItem('🔢', '7 Enerjisi', 'Numeroloji', '8 Mar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionTitleRow(title: 'SON BAKILAN FALLAR'),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final item = _items[i];
                return SizedBox(
                  width: 148,
                  child: FortuneGlassCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => context.push('/fortune/tarot'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 28)),
                        const Spacer(),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PremiumTypography.title(context).copyWith(
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${item.type} · ${item.date}',
                          style: PremiumTypography.label(context).copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentItem {
  const _RecentItem(this.emoji, this.title, this.type, this.date);
  final String emoji;
  final String title;
  final String type;
  final String date;
}

class _AiSuggestionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: FortuneGlassCard(
        elevated: true,
        accent: AppColors.accentPurple,
        onTap: () => context.push('/fortune/tarot'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6D28D9).withValues(alpha: 0.55),
                const Color(0xFF4C1D95).withValues(alpha: 0.35),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI ÖNERİSİ',
                    style: PremiumTypography.label(context).copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Bugün senin için Tarot ve Yıldız Falı uygun görünüyor…',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push('/fortune/tarot'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              child: const Text(
                'KEŞFET →',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: FortuneGlassCard(
        elevated: true,
        accent: AppColors.coinGold,
        onTap: () => context.push('/premium-membership'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.coinGold.withValues(alpha: 0.2),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.coinGold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PREMIUM'A GEÇ",
                        style: PremiumTypography.title(context).copyWith(
                          color: AppColors.coinGold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sınırsız fal, reklamsız deneyim ve özel yorumlar.',
                        style: PremiumTypography.body(context).copyWith(
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => context.push('/premium-membership'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.coinGold,
                    side: BorderSide(
                      color: AppColors.coinGold.withValues(alpha: 0.7),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'KEŞFET →',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _premiumPerk(Icons.all_inclusive_rounded, 'Sınırsız Fal'),
                _premiumPerk(Icons.block_rounded, 'Reklamsız'),
                _premiumPerk(Icons.auto_awesome_rounded, 'Özel Yorum'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumPerk(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.coinGold.withValues(alpha: 0.9)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({
    required this.title,
    this.onSeeAll,
    this.seeAllLabel = 'Tümünü Gör >',
  });

  final String title;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: PremiumTypography.label(context).copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              seeAllLabel,
              style: TextStyle(
                color: AppColors.accentCyan.withValues(alpha: 0.95),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
