import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../navigation/fortune_card_navigation.dart';
import '../providers/fortune_types_display_provider.dart';
import '../widgets/fortune_hub_2026/fortune_hub_kit.dart';

/// Tüm fal türleri — gerçek API/katalog vitrini, Premium 2026 kartları.
class FortuneTypesAllPage extends ConsumerWidget {
  const FortuneTypesAllPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(fortuneTypesDisplayProvider);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 400 ? 3 : 2;
    final aspect = columns == 3 ? 0.82 : 1.05;

    return Scaffold(
      backgroundColor: FortuneUi.bg0,
      appBar: AppBar(
        backgroundColor: FortuneUi.bg2,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Fal Türleri',
          style: FortuneUi.display(20, weight: FontWeight.w700),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: FortuneUi.backgroundGradient,
        ),
        child: SafeArea(
          top: false,
          child: entries.when(
            loading: () => GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: _delegate(columns, aspect),
              itemCount: 9,
              itemBuilder: (_, _) => DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(FortuneUi.radiusSm),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: FortuneUi.lilac.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            error: (_, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FortuneInlineState(
                  icon: Icons.refresh_rounded,
                  message: 'Fal türleri yüklenemedi',
                  actionLabel: 'Tekrar dene',
                  onAction: () => invalidateFortuneTypesDisplay(ref),
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FortuneInlineState(
                      icon: Icons.auto_awesome_rounded,
                      message: 'Şu anda fal türleri bulunamadı',
                      actionLabel: 'Yenile',
                      onAction: () => invalidateFortuneTypesDisplay(ref),
                    ),
                  ),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                physics: const BouncingScrollPhysics(),
                gridDelegate: _delegate(columns, aspect),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final e = list[i];
                  return FortuneCategoryCard(
                    slug: e.slug,
                    title: e.title,
                    subtitle: e.subtitle,
                    imageUrl: e.imageUrl,
                    accent: e.accent,
                    jetonCost: e.jetonCost,
                    compact: columns == 3,
                    onTap: () => openFortuneTypeDestination(context, e),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount _delegate(
    int columns,
    double aspect,
  ) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: aspect,
    );
  }
}
