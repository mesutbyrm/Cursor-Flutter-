import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../../fortune/presentation/widgets/premium_2026/premium_section_header.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_liquid_surface.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_tokens.dart';
import '../../domain/entities/bana_ozel_entities.dart';
import '../navigation/bana_ozel_navigation.dart';
import '../providers/bana_ozel_providers.dart';
import 'bana_ozel_premium_card.dart';

/// Fal & Tarot hub — Bana Özel premium yatay vitrin (`GET /api/bana-ozel`).
class BanaOzelHubSection extends ConsumerWidget {
  const BanaOzelHubSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(banaOzelCatalogProvider);
    final cardW = BanaOzelPremiumCard.cardWidthFor(context);
    final cardH = BanaOzelPremiumCard.cardHeight;
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: catalog.when(
        loading: () => _SectionFrame(
          jetonLabel: jetonLabel,
          child: SizedBox(
            height: cardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => BanaOzelPremiumCardSkeleton(width: cardW),
            ),
          ),
        ),
        error: (_, __) => _SectionFrame(
          jetonLabel: jetonLabel,
          child: _HubInlineState(
            height: cardH,
            icon: Icons.refresh_rounded,
            message: 'Bana Özel içerikleri yüklenemedi',
            actionLabel: 'Tekrar Dene',
            onAction: () => refreshBanaOzelCatalog(ref),
          ),
        ),
        data: (data) {
          if (data.items.isEmpty) {
            return _SectionFrame(
              jetonLabel: jetonLabel,
              child: _HubInlineState(
                height: cardH * 0.65,
                icon: Icons.auto_awesome_rounded,
                message: 'Size özel yeni içerikler hazırlanıyor.',
                actionLabel: 'Kataloğu Aç',
                onAction: () => openBanaOzelCatalog(context),
              ),
            );
          }

          final preview = data.items.take(8).toList();
          return _SectionFrame(
            jetonLabel: jetonLabel,
            balanceLine:
                '💰 ${data.jetonBalance} $jetonLabel · ${data.items.length} içerik',
            streak: data.streak,
            child: SizedBox(
              height: cardH,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: preview.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final item = preview[i];
                  return BanaOzelPremiumCard(
                    item: item,
                    affordable: data.canAffordItem(item),
                    width: cardW,
                    height: cardH,
                    onTap: () => openBanaOzelCatalog(context, slug: item.slug),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({
    required this.jetonLabel,
    required this.child,
    this.balanceLine,
    this.streak,
  });

  final String jetonLabel;
  final Widget child;
  final String? balanceLine;
  final BanaOzelStreakEntity? streak;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: PremiumSectionHeader(
                title: 'BANA ÖZEL',
                icon: Icons.auto_fix_high_rounded,
                iconColor: UltraFortuneTokens.metallicGold,
              ),
            ),
            TextButton(
              onPressed: () => openBanaOzelCatalog(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Tümü >',
                style: TextStyle(
                  color: UltraFortuneTokens.softLilac.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        if (balanceLine != null) ...[
          const SizedBox(height: 4),
          Text(
            balanceLine!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
        if (streak != null &&
            (streak!.currentStreak > 0 || streak!.totalFortunes > 0)) ...[
          const SizedBox(height: 6),
          _StreakLine(streak: streak!),
        ],
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _StreakLine extends StatelessWidget {
  const _StreakLine({required this.streak});

  final BanaOzelStreakEntity streak;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (streak.currentStreak > 0) {
      parts.add('🔥 ${streak.currentStreak} günlük seri');
    }
    if (streak.totalFortunes > 0) {
      parts.add('${streak.totalFortunes} fal');
    }
    return Text(
      parts.join(' · '),
      style: TextStyle(
        color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.9),
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
    );
  }
}

class _HubInlineState extends StatelessWidget {
  const _HubInlineState({
    required this.height,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final double height;
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return UltraFortuneLiquidSurface(
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: SizedBox(
        height: height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.white54),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: UltraFortuneTokens.metallicGold,
                  foregroundColor: const Color(0xFF1A0A32),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
