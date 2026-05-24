import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../data/fortune_catalog.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_hub_type_card.dart';

/// Tüm fal türleri — 3 sütunlu grid.
class FortuneTypesAllPage extends StatelessWidget {
  const FortuneTypesAllPage({super.key});

  @override
  Widget build(BuildContext context) {
    final types = FortuneCatalog.types
        .where((t) => !t.isDaily)
        .toList();
    final subtitles = {
      for (final e in FortuneCatalog.hubFortuneEntries) e.slug: e.subtitle,
    };

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
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: types.length,
          itemBuilder: (context, i) {
            final type = types[i];
            final subtitle = subtitles[type.slug] ?? type.description;
            return FortuneHubTypeCard(
              type: type,
              subtitle: subtitle,
              onTap: () => context.push('/fortune/${type.slug}'),
            );
          },
        ),
      ),
    );
  }
}
