import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/widgets/premium_2026/home_horizontal_list.dart';
import '../../../home/presentation/widgets/premium_2026/home_section_shell.dart';
import '../navigation/bana_ozel_navigation.dart';
import '../providers/bana_ozel_providers.dart';
import 'bana_ozel_premium_card.dart';

/// Ana sayfa — Bana Özel V2 yatay vitrin (`GET /api/bana-ozel`).
class HomeBanaOzelSection extends ConsumerWidget {
  const HomeBanaOzelSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(banaOzelCatalogProvider);
    final cardW = BanaOzelPremiumCard.cardWidthFor(context);
    final cardH = BanaOzelPremiumCard.cardHeight;

    return catalog.when(
      loading: () => HomeSectionShell(
        emoji: '✨',
        title: 'Bana Özel',
        actionLabel: 'Tümü >',
        onAction: () => openBanaOzelCatalog(context),
        contentHeight: cardH + 8,
        loading: HomeHorizontalList(
          height: cardH,
          separatorWidth: 14,
          itemCount: 3,
          itemBuilder: (_, _) => BanaOzelPremiumCardSkeleton(width: cardW),
        ),
      ),
      error: (_, __) => HomeSectionShell(
        emoji: '✨',
        title: 'Bana Özel',
        actionLabel: 'Tümü >',
        onAction: () => openBanaOzelCatalog(context),
        errorMessage: 'Bana Özel içerikleri yüklenemedi',
        onRetry: () => refreshBanaOzelCatalog(ref),
      ),
      data: (data) {
        if (data.items.isEmpty) {
          return HomeSectionShell(
            emoji: '✨',
            title: 'Bana Özel',
            actionLabel: 'Tümü >',
            onAction: () => openBanaOzelCatalog(context),
            emptyIcon: Icons.auto_awesome_rounded,
            emptyMessage: 'Size özel yeni içerikler hazırlanıyor.',
          );
        }
        final preview = data.items.take(8).toList();
        return HomeSectionShell(
          emoji: '✨',
          title: 'Bana Özel',
          actionLabel: 'Tümü >',
          onAction: () => openBanaOzelCatalog(context),
          child: RepaintBoundary(
            child: HomeHorizontalList(
              height: cardH,
              separatorWidth: 14,
              itemCount: preview.length,
              itemBuilder: (_, i) {
                final item = preview[i];
                return BanaOzelPremiumCard(
                  item: item,
                  affordable: data.jetonBalance >= item.jetonCost,
                  width: cardW,
                  height: cardH,
                  onTap: () => openBanaOzelCatalog(context, slug: item.slug),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
