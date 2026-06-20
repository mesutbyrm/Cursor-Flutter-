import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/premium_2026/premium_2026.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../data/fortune_catalog.dart';
import '../data/fortune_popular_readings.dart';
import '../services/fortune_reading_coordinator.dart';
import 'fortune_glass_card.dart';
import 'fortune_type_network_image.dart';

/// En çok bakılan fallar — yatay kaydırmalı liste.
class FortunePopularReadingsSection extends ConsumerWidget {
  const FortunePopularReadingsSection({
    super.key,
    this.excludeSlug,
    this.onOpenReading,
  });

  final String? excludeSlug;
  final void Function(FortuneTypeEntity type)? onOpenReading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = excludeSlug != null
        ? FortunePopularReadings.excluding(excludeSlug!)
        : FortunePopularReadings.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'EN ÇOK BAKILAN FALLAR',
          style: PremiumTypography.label(context).copyWith(
            letterSpacing: 1.1,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final item = items[i];
              final type = FortuneCatalog.bySlug(item.slug);
              if (type == null) return const SizedBox.shrink();
              return _PopularCard(
                item: item,
                type: type,
                onTap: () {
                  if (onOpenReading != null) {
                    onOpenReading!(type);
                  } else {
                    FortuneReadingCoordinator.openReading(
                      context: context,
                      ref: ref,
                      type: type,
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PopularCard extends StatelessWidget {
  const _PopularCard({
    required this.item,
    required this.type,
    required this.onTap,
  });

  final FortunePopularReading item;
  final FortuneTypeEntity type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: FortuneGlassCard(
        padding: EdgeInsets.zero,
        accent: type.accent,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 88,
              child: FortuneTypeNetworkImage(
                slug: type.slug,
                accent: type.accent,
                borderRadius: 0,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PremiumTypography.title(context).copyWith(
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PremiumTypography.label(context).copyWith(
                        fontSize: 10,
                        color: type.accent,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.visibility_rounded,
                          size: 12,
                          color: context.colors.onSurfaceMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.viewLabel,
                          style: PremiumTypography.label(context).copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
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
