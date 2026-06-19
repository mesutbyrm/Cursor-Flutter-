import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../data/fortune_type_showcase.dart';
import '../services/fortune_reading_coordinator.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_mystic_bar_button.dart';
import '../widgets/fortune_mystic_title_bar.dart';
import '../widgets/fortune_popular_readings_section.dart';
import '../widgets/fortune_type_showcase_card.dart';

/// Fal türü vitrin — üstte Falını Aç, altta en çok bakılan fallar; doğrudan sonuç.
class FortuneTypeIntroPage extends ConsumerWidget {
  const FortuneTypeIntroPage({super.key, required this.type});

  final FortuneTypeEntity type;

  Future<void> _openFortune(BuildContext context, WidgetRef ref) {
    return FortuneReadingCoordinator.openReading(
      context: context,
      ref: ref,
      type: type,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showcase = FortuneTypeShowcase.forSlug(type.slug);
    if (showcase == null) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('Geri'),
          ),
        ),
      );
    }

    void open(FortuneTypeEntity t) {
      FortuneReadingCoordinator.openReading(
        context: context,
        ref: ref,
        type: t,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FortuneMysticBackground(
        child: Column(
          children: [
            FortuneMysticTitleBar(
              title: showcase.numberedTitle,
              onBack: () => context.pop(),
              trailing: FortuneMysticBarButton(
                icon: Icons.star_outline_rounded,
                onPressed: () {},
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: PremiumMotion.listPhysics,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FortuneOpenFortuneButton(
                      accent: type.accent,
                      onPressed: () => _openFortune(context, ref),
                    ),
                    const SizedBox(height: 16),
                    FortuneTypeShowcaseCard(
                      showcase: showcase,
                      compact: false,
                      showCardHeader: false,
                      showOpenButton: false,
                      onOpenFortune: () => _openFortune(context, ref),
                    ),
                    const SizedBox(height: 24),
                    FortunePopularReadingsSection(
                      excludeSlug: type.slug,
                      onOpenReading: open,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
