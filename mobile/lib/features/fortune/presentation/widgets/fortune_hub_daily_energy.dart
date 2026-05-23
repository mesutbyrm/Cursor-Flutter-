import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../data/fortune_catalog.dart';
import 'fortune_hub_insight_banner.dart';

/// GÜNLÜK ENERJİN — 3 kart + sezgi banner (mockup).
class FortuneHubDailyEnergy extends StatelessWidget {
  const FortuneHubDailyEnergy({super.key});

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                size: 18,
                color: _gold.withValues(alpha: 0.95),
                shadows: [
                  Shadow(
                    color: _gold.withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Text(
                'GÜNLÜK ENERJİN',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.8,
                  color: _gold,
                ),
              ),
              const Spacer(),
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
                    color: AppColors.accentPurple.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _EnergyCard(
                    label: 'ENERJİ',
                    value: 'Yüksek',
                    icon: Icons.bolt_rounded,
                    iconColor: Color(0xFFFBBF24),
                    progress: 0.85,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _EnergyCard(
                    label: 'ŞANSLI SAYI',
                    value: '7',
                    icon: Icons.eco_rounded,
                    iconColor: Color(0xFF4ADE80),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _EnergyCard(
                    label: 'ŞANSLI RENK',
                    value: 'Mor',
                    icon: Icons.diamond_rounded,
                    iconColor: Color(0xFFE879F9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FortuneHubInsightBanner(
            onTap: () => context.push(
              '/fortune/${FortuneCatalog.dailyFortune.slug}',
            ),
          ),
        ],
      ),
    );
  }
}

class _EnergyCard extends StatelessWidget {
  const _EnergyCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.progress,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final double? progress;

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1A0B2E).withValues(alpha: 0.85),
        border: Border.all(
          color: AppColors.accentPurple.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: _gold.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                color: iconColor,
              ),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}
