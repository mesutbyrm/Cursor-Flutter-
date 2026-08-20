import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_palette.dart';
import '../providers/fortune_types_display_provider.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/premium_2026/fortune_premium_card.dart';

/// Tüm fal türleri — gerçek API + V2 premium grid.
class FortuneTypesAllPage extends ConsumerWidget {
  const FortuneTypesAllPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(fortuneTypesDisplayProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.palette.surface,
        elevation: 0,
        title: Text(
          'Fal Türleri',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: FortuneMysticBackground(
        child: entries.when(
          loading: () => GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: _gridDelegate(context),
            itemCount: 9,
            itemBuilder: (_, _) => const FortunePremiumCardSkeleton(
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Fal türleri yüklenemedi'),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => invalidateFortuneTypesDisplay(ref),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const Center(
                child: Text('Henüz fal türü bulunamadı.'),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const BouncingScrollPhysics(),
              gridDelegate: _gridDelegate(context),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final e = list[i];
                return LayoutBuilder(
                  builder: (context, constraints) {
                    return FortunePremiumCard(
                      slug: e.slug,
                      title: e.title,
                      subtitle: e.subtitle,
                      imageUrl: e.imageUrl,
                      jetonCost: e.jetonCost,
                      accent: e.accent,
                      emoji: e.emoji,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      compact: true,
                      onTap: () => context.push('/fortune/${e.slug}'),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  SliverGridDelegateWithFixedCrossAxisCount _gridDelegate(
    BuildContext context,
  ) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: MediaQuery.sizeOf(context).width >= 400 ? 3 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.72,
    );
  }
}
