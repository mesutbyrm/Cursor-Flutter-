import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:canlifal_social/features/fortune/presentation/navigation/fortune_card_navigation.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_types_display_provider.dart';
import 'package:canlifal_social/features/fortune/presentation/widgets/premium_2026/fortune_premium_card.dart';
import '../premium_2026/home_horizontal_list.dart';
import '../premium_2026/home_section_shell.dart';

/// Fal & Tarot vitrin — V2 premium kart + gerçek backend API.
class FortuneSection extends ConsumerWidget {
  const FortuneSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(fortuneTypesDisplayProvider);
    final cardW = FortunePremiumCard.cardWidthFor(context);
    final cardH = FortunePremiumCard.cardHeight;

    return entries.when(
      loading: () => HomeSectionShell(
        emoji: '🔮',
        title: 'Fal & Tarot',
        actionLabel: 'Tüm Fal Türleri >',
        onAction: () => openFortuneTypesCatalog(context),
        contentHeight: cardH + 8,
        loading: HomeHorizontalList(
          height: cardH,
          separatorWidth: 14,
          itemCount: 5,
          itemBuilder: (_, _) => FortunePremiumCardSkeleton(width: cardW),
        ),
      ),
      error: (_, __) => HomeSectionShell(
        emoji: '🔮',
        title: 'Fal & Tarot',
        actionLabel: 'Tüm Fal Türleri >',
        onAction: () => openFortuneTypesCatalog(context),
        errorMessage: 'Fal türleri yüklenemedi',
        onRetry: () => invalidateFortuneTypesDisplay(ref),
      ),
      data: (list) {
        if (list.isEmpty) {
          return HomeSectionShell(
            emoji: '🔮',
            title: 'Fal & Tarot',
            actionLabel: 'Tüm Fal Türleri >',
            onAction: () => openFortuneTypesCatalog(context),
            emptyIcon: Icons.auto_awesome_rounded,
            emptyMessage: 'Şu anda fal türleri bulunamadı',
          );
        }
        final preview = list.take(14).toList();
        return HomeSectionShell(
          emoji: '🔮',
          title: 'Fal & Tarot',
          actionLabel: 'Tüm Fal Türleri >',
          onAction: () => openFortuneTypesCatalog(context),
          child: RepaintBoundary(
            child: HomeHorizontalList(
              height: cardH,
              separatorWidth: 14,
              itemCount: preview.length,
              itemBuilder: (context, i) {
                final e = preview[i];
                return FortunePremiumCard(
                  slug: e.slug,
                  title: e.title,
                  subtitle: e.subtitle,
                  imageUrl: e.imageUrl,
                  jetonCost: e.jetonCost,
                  accent: e.accent,
                  emoji: e.emoji,
                  width: cardW,
                  height: cardH,
                  onTap: () => openFortuneTypeDestination(context, e),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
