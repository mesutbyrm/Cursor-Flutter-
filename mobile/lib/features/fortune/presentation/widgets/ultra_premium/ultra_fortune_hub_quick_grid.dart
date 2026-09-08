import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/performance/list_perf.dart';
import '../../data/fortune_catalog.dart';
import '../fortune_hub_type_card.dart';
import '../premium_2026/premium_section_header.dart';
import '../../navigation/fortune_card_navigation.dart';
import 'ultra_fortune_tokens.dart';

/// Popüler 8 fal türü — katalog `hubFortuneEntries` 2×4 grid.
class UltraFortuneHubQuickGrid extends StatelessWidget {
  const UltraFortuneHubQuickGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = FortuneCatalog.hubFortuneTypes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: PremiumSectionHeader(
                  title: 'POPÜLER FAL TÜRLERİ',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: UltraFortuneTokens.metallicGold,
                ),
              ),
              TextButton(
                onPressed: () => openFortuneTypesCatalog(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Tümü >',
                  style: TextStyle(
                    color: UltraFortuneTokens.softLilac.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 2;
              const spacing = 12.0;
              const aspect = 1.05;
              final gridHeight = ListPerf.nestedGridHeight(
                itemCount: entries.length,
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: aspect,
                crossAxisExtent: constraints.maxWidth,
              );
              return SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: aspect,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return FortuneHubTypeCard(
                      type: entry.type,
                      subtitle: entry.subtitle,
                      onTap: () => context.push('/fortune/${entry.type.slug}'),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
