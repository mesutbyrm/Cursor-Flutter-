import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../data/fortune_type_showcase.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_type_showcase_card.dart';

/// Tüm fal türleri — mockup vitrin kartları (14 tür).
class FortuneTypesAllPage extends StatelessWidget {
  const FortuneTypesAllPage({super.key});

  @override
  Widget build(BuildContext context) {
    final showcases = FortuneTypeShowcase.all;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0118),
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
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          physics: const BouncingScrollPhysics(),
          itemCount: showcases.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (context, i) {
            final showcase = showcases[i];
            final slug = showcase.type.slug;
            return FortuneTypeShowcaseCard(
              showcase: showcase,
              onOpenFortune: () => context.push('/fortune/$slug'),
            );
          },
        ),
      ),
    );
  }
}
