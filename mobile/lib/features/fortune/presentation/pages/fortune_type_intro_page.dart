import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../data/fortune_type_showcase.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_mystic_bar_button.dart';
import '../widgets/fortune_mystic_title_bar.dart';
import '../widgets/fortune_type_showcase_card.dart';

/// Fal türü vitrin — mockup tam ekran (geri, yıldız, Falını Aç → oturum).
class FortuneTypeIntroPage extends StatelessWidget {
  const FortuneTypeIntroPage({super.key, required this.type});

  final FortuneTypeEntity type;

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: AppColors.background,
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
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: FortuneTypeShowcaseCard(
                  showcase: showcase,
                  compact: false,
                  showCardHeader: false,
                  onOpenFortune: () =>
                      context.push('/fortune/${type.slug}/session'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
