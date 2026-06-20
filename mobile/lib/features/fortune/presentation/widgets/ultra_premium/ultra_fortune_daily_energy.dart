import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/fortune_catalog.dart';
import '../premium_2026/premium_section_header.dart';
import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_tokens.dart';

/// GÜNLÜK ENERJİN — yatay swipe kristal cam kartlar.
class UltraFortuneDailyEnergy extends StatelessWidget {
  const UltraFortuneDailyEnergy({super.key});

  static const _cards = [
    _EnergyItem(
      label: 'Enerji',
      value: 'Yüksek',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFBBF24),
    ),
    _EnergyItem(
      label: 'Şanslı Renk',
      value: 'Mor',
      icon: Icons.diamond_rounded,
      color: UltraFortuneTokens.softLilac,
    ),
    _EnergyItem(
      label: 'Şanslı Sayı',
      value: '7',
      icon: Icons.eco_rounded,
      color: Color(0xFF4ADE80),
    ),
    _EnergyItem(
      label: 'Ay Evresi',
      value: 'Şişkin Ay',
      icon: Icons.nightlight_round,
      color: UltraFortuneTokens.metallicGold,
    ),
    _EnergyItem(
      label: 'Burç Mesajı',
      value: 'Bugün Işıldıyorsun',
      icon: Icons.star_rounded,
      color: UltraFortuneTokens.electricPurple,
    ),
  ];

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
            itemCount: _cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final card = _cards[index];
              return _EnergyCrystalCard(item: card);
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
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _EnergyCrystalCard extends StatelessWidget {
  const _EnergyCrystalCard({required this.item});

  final _EnergyItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: UltraFortuneLiquidSurface(
        elevated: true,
        borderRadius: BorderRadius.circular(22),
        padding: const EdgeInsets.all(14),
        blur: 42,
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
    );
  }
}
