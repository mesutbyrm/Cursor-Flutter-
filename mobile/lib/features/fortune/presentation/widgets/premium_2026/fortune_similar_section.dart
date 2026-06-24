import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/fortune_type_entity.dart';
import '../../data/fortune_catalog.dart';
import '../../data/fortune_similar_recommendations.dart';
import '../premium_2026/cinematic_fortune_grid_card.dart';
import '../premium_2026/premium_section_header.dart';

/// Benzer fal önerileri — sonuç ekranı altı.
class FortuneSimilarSection extends StatelessWidget {
  const FortuneSimilarSection({
    super.key,
    required this.currentSlug,
    this.onOpen,
  });

  final String currentSlug;
  final void Function(FortuneTypeEntity type)? onOpen;

  @override
  Widget build(BuildContext context) {
    final slugs = FortuneSimilarRecommendations.slugsFor(currentSlug);
    final types = <FortuneTypeEntity>[];
    for (final slug in slugs) {
      final t = FortuneCatalog.bySlug(slug);
      if (t != null && !t.isDaily) types.add(t);
    }
    if (types.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: PremiumSectionHeader(
            title: 'Benzer Fallar',
            icon: Icons.auto_awesome_rounded,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: types.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final type = types[i];
              return SizedBox(
                width: 148,
                child: CinematicFortuneGridCard(
                  type: type,
                  title: type.title,
                  subtitle: type.description,
                  radius: 22,
                  onTap: () {
                    if (onOpen != null) {
                      onOpen!(type);
                    } else {
                      context.push('/fortune/${type.slug}');
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
