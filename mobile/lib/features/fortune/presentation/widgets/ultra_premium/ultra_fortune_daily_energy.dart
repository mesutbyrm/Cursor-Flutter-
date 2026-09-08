import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/fortune_catalog.dart';
import '../../providers/fortune_hub_providers.dart';
import '../data/fortune_type_images.dart';
import '../premium_2026/premium_section_header.dart';
import 'ultra_fortune_cover_backdrop.dart';
import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_tokens.dart';

/// GÜNLÜK ENERJİN — API burç + türetilmiş enerji kartları.
class UltraFortuneDailyEnergy extends ConsumerWidget {
  const UltraFortuneDailyEnergy({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(fortuneDailyInsightsProvider);

    return insights.when(
      loading: () => const _DailyEnergyBody(
        items: _EnergyItem.fallback(),
      ),
      error: (_, _) => const _DailyEnergyBody(
        items: _EnergyItem.fallback(),
      ),
      data: (data) => _DailyEnergyBody(
        items: _EnergyItem.fromInsights(data),
      ),
    );
  }
}

class _DailyEnergyBody extends StatelessWidget {
  const _DailyEnergyBody({required this.items});

  final List<_EnergyItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              const Expanded(
                child: PremiumSectionHeader(
                  title: 'GÜNLÜK ENERJİN',
                  icon: Icons.bolt_rounded,
                  iconColor: UltraFortuneTokens.electricPurple,
                ),
              ),
              TextButton(
                onPressed: () => context.push(
                  '/fortune/${FortuneCatalog.dailyFortune.slug}',
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Tümünü Gör >',
                  style: TextStyle(
                    color: UltraFortuneTokens.softLilac.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 132,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final card = items[index];
              return _EnergyCrystalCard(
                item: card,
                onTap: () => context.push(card.route),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EnergyItem {
  const _EnergyItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.coverSlug,
    required this.route,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String coverSlug;
  final String route;

  static List<_EnergyItem> fallback() => [
        (
          label: 'Enerji',
          value: 'Yüksek',
          icon: Icons.bolt_rounded,
          color: Color(0xFFFBBF24),
          coverSlug: 'gunluk-fal',
          route: '/fortune/gunluk-fal',
        ),
        (
          label: 'Şanslı Renk',
          value: 'Mor',
          icon: Icons.diamond_rounded,
          color: UltraFortuneTokens.softLilac,
          coverSlug: 'aura-analizi',
          route: '/fortune/gunluk-fal',
        ),
        (
          label: 'Şanslı Sayı',
          value: '7',
          icon: Icons.eco_rounded,
          color: Color(0xFF4ADE80),
          coverSlug: 'numeroloji',
          route: '/fortune/gunluk-fal',
        ),
        (
          label: 'Ay Evresi',
          value: 'Şişkin Ay',
          icon: Icons.nightlight_round,
          color: UltraFortuneTokens.metallicGold,
          coverSlug: 'yildiz-haritasi',
          route: '/fortune/yildiz-haritasi',
        ),
        (
          label: 'Burç Mesajı',
          value: 'Bugün iç sesine kulak ver',
          icon: Icons.star_rounded,
          color: UltraFortuneTokens.electricPurple,
          coverSlug: 'yildiz-haritasi',
          route: '/fortune/yildiz-haritasi',
        ),
      ].map(_fromRecord).toList();

  static List<_EnergyItem> fromInsights(FortuneDailyInsights data) => [
        (
          label: 'Enerji',
          value: data.energyLabel,
          icon: Icons.bolt_rounded,
          color: const Color(0xFFFBBF24),
          coverSlug: 'gunluk-fal',
          route: '/fortune/gunluk-fal',
        ),
        (
          label: 'Şanslı Renk',
          value: data.luckyColor,
          icon: Icons.diamond_rounded,
          color: UltraFortuneTokens.softLilac,
          coverSlug: 'aura-analizi',
          route: '/fortune/gunluk-fal',
        ),
        (
          label: 'Şanslı Sayı',
          value: data.luckyNumber,
          icon: Icons.eco_rounded,
          color: const Color(0xFF4ADE80),
          coverSlug: 'numeroloji',
          route: '/fortune/gunluk-fal',
        ),
        (
          label: 'Ay Evresi',
          value: data.moonPhase,
          icon: Icons.nightlight_round,
          color: UltraFortuneTokens.metallicGold,
          coverSlug: 'yildiz-haritasi',
          route: '/fortune/yildiz-haritasi',
        ),
        (
          label: 'Burç Mesajı',
          value: data.burcMessage,
          icon: Icons.star_rounded,
          color: UltraFortuneTokens.electricPurple,
          coverSlug: 'yildiz-haritasi',
          route: '/fortune/yildiz-haritasi',
        ),
      ].map(_fromRecord).toList();

  static _EnergyItem _fromRecord(
    ({
      String label,
      String value,
      IconData icon,
      Color color,
      String coverSlug,
      String route,
    }) r,
  ) {
    return _EnergyItem(
      label: r.label,
      value: r.value,
      icon: r.icon,
      color: r.color,
      coverSlug: r.coverSlug,
      route: r.route,
    );
  }
}

class _EnergyCrystalCard extends StatelessWidget {
  const _EnergyCrystalCard({required this.item, this.onTap});

  final _EnergyItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = FortuneTypeImages.glowColor(item.coverSlug);
    return SizedBox(
      width: 128,
      child: UltraFortuneLiquidSurface(
        onTap: onTap,
        elevated: true,
        borderRadius: BorderRadius.circular(22),
        padding: EdgeInsets.zero,
        blur: 42,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              UltraFortuneCoverBackdrop(
                slug: item.coverSlug,
                accent: accent,
                opacity: 0.34,
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            item.color.withValues(alpha: 0.35),
                            item.color.withValues(alpha: 0.08),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: item.color.withValues(alpha: 0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      item.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
