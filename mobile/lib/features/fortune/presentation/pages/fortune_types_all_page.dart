import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/fortune_card_navigation.dart';
import '../providers/fortune_types_display_provider.dart';
import '../widgets/premium_2026/fortune_premium_card.dart';
import '../widgets/ultra_premium/ultra_fortune_cosmic_background.dart';
import '../widgets/ultra_premium/ultra_fortune_state_panel.dart';
import '../widgets/ultra_premium/ultra_fortune_tokens.dart';

/// Tüm fal türleri — gerçek API + V2 premium grid.
class FortuneTypesAllPage extends ConsumerWidget {
  const FortuneTypesAllPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(fortuneTypesDisplayProvider);

    return Scaffold(
      backgroundColor: UltraFortuneTokens.deepNight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Fal Türleri',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: UltraFortuneCosmicBackground(
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: UltraFortuneStatePanel(
                icon: Icons.refresh_rounded,
                message: 'Fal türleri yüklenemedi',
                actionLabel: 'Tekrar Dene',
                onAction: () => invalidateFortuneTypesDisplay(ref),
              ),
            ),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: UltraFortuneStatePanel(
                    icon: Icons.auto_awesome_rounded,
                    message: 'Şu anda fal türleri bulunamadı',
                    actionLabel: 'Yenile',
                    onAction: () => invalidateFortuneTypesDisplay(ref),
                  ),
                ),
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
                      showEmojiInTitle: false,
                      onTap: () => openFortuneTypeDestination(context, e),
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
