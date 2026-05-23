import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover_refresh.dart';
import '../data/fortune_catalog.dart';
import '../widgets/fortune_hub_app_bar.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_hub_type_card.dart';

/// Fal & Tarot ana sekme — mockup: enerji, türler, son fallar, AI, premium.
class FortuneTarotHubPage extends ConsumerWidget {
  const FortuneTarotHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FortuneMysticBackground(
        child: DiscoverRefresh.wrap(
          onRefresh: () async {},
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: FortuneHubAppBar()),
              SliverToBoxAdapter(child: _HeroBanner()),
              SliverToBoxAdapter(child: _DailyEnergySection()),
              SliverToBoxAdapter(child: _FortuneTypesHeader()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.02,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final entry = FortuneCatalog.hubFortuneTypes[i];
                      return FortuneHubTypeCard(
                        type: entry.type,
                        subtitle: entry.subtitle,
                        onTap: () =>
                            context.push('/fortune/${entry.type.slug}'),
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

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              height: 168,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2D1B4E), Color(0xFF0F0A1E)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    top: 10,
                    child: Icon(
                      Icons.blur_circular_rounded,
                      size: 120,
                      color: AppColors.accentPurple.withValues(alpha: 0.35),
                    ),
                  ),
                  Positioned(
                    right: 24,
                    bottom: 20,
                    child: Text(
                      '🕯️',
                      style: TextStyle(
                        fontSize: 28,
                        shadows: [
                          Shadow(
                            color: AppColors.accentPurple.withValues(alpha: 0.8),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(text: 'Kendini keşfet, geleceğini '),
                        TextSpan(
                          text: 'aydınlat',
                          style: TextStyle(
                            color: Color(0xFFC084FC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fal ve tarotun mistik dünyasına hoş geldin.',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/fortune/${FortuneCatalog.dailyFortune.slug}',
                    ),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('FALINI AÇ'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyEnergySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitleRow(
            title: 'GÜNLÜK ENERJİN',
            icon: Icons.star_rounded,
            onSeeAll: () => context.push(
              '/fortune/${FortuneCatalog.dailyFortune.slug}',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 108,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: const [
                _EnergyChip(
                  label: 'ENERJİ',
                  value: 'Yüksek',
                  icon: Icons.bolt_rounded,
                  progress: 0.85,
                  color: Color(0xFFFBBF24),
                ),
                SizedBox(width: 10),
                _EnergyChip(
                  label: 'ŞANSLI SAYI',
                  value: '7',
                  icon: Icons.eco_rounded,
                  color: Color(0xFF4ADE80),
                ),
                SizedBox(width: 10),
                _EnergyChip(
                  label: 'ŞANSLI RENK',
                  value: 'Mor',
                  icon: Icons.diamond_rounded,
                  color: Color(0xFFE879F9),
                ),
                SizedBox(width: 10),
                _EnergyChip(
                  label: 'AY ETKİSİ',
                  value: 'Güçlü',
                  icon: Icons.nightlight_round,
                  color: Color(0xFF93C5FD),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bugün sezgilerin güçlü, iç sesini dinlemeyi unutma.',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.95),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyChip extends StatelessWidget {
  const _EnergyChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.progress,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textMuted.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                color: color,
              ),
            ),
          ],
        ],
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
                return GestureDetector(
                  onTap: () => context.push('/fortune/tarot'),
                  child: Container(
                    width: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: AppColors.accentPurple.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 28)),
                        const Spacer(),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${item.type} · ${item.date}',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.9),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF6D28D9), Color(0xFF4C1D95)],
          ),
          boxShadow: AppColors.glowShadow(
            AppColors.accentPurple,
            blur: 16,
          ),
        ),
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
                  const Text(
                    'AI ÖNERİSİ',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.8,
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
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF3D2E0A).withValues(alpha: 0.95),
              const Color(0xFF1A1408),
            ],
          ),
          border: Border.all(
            color: AppColors.coinGold.withValues(alpha: 0.45),
          ),
        ),
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "PREMIUM'A GEÇ",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.coinGold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sınırsız fal, reklamsız deneyim ve özel yorumlar.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
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
    this.icon,
    this.onSeeAll,
    this.seeAllLabel = 'Tümünü Gör >',
  });

  final String title;
  final IconData? icon;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.accentPink),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
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
