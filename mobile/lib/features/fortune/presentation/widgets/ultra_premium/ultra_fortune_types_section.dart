import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/performance/list_perf.dart';
import '../../navigation/fortune_card_navigation.dart';
import '../../providers/fortune_types_display_provider.dart';
import '../premium_2026/fortune_premium_card.dart';
import '../premium_2026/premium_section_header.dart';
import 'ultra_fortune_tokens.dart';

/// FAL TÜRLERİ bölümü — gerçek API + V2 premium grid.
class UltraFortuneTypesSection extends ConsumerStatefulWidget {
  const UltraFortuneTypesSection({super.key});

  @override
  ConsumerState<UltraFortuneTypesSection> createState() =>
      _UltraFortuneTypesSectionState();
}

class _UltraFortuneTypesSectionState extends ConsumerState<UltraFortuneTypesSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(fortuneTypesDisplayProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: PremiumSectionHeader(
                  title: 'FAL TÜRLERİ',
                  icon: Icons.grid_view_rounded,
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
                  'Tüm Fal Türleri >',
                  style: TextStyle(
                    color: UltraFortuneTokens.softLilac.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          entries.when(
            loading: () => _buildGrid(
              context,
              itemCount: 6,
              itemBuilder: (_, _) => const FortunePremiumCardSkeleton(
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            error: (_, __) => Column(
              children: [
                const Text('Fal türleri yüklenemedi'),
                TextButton(
                  onPressed: () => invalidateFortuneTypesDisplay(ref),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Text('Henüz fal türü bulunamadı.');
              }
              final preview = list.take(10).toList();
              return _buildGrid(
                context,
                itemCount: preview.length,
                itemBuilder: (context, index) {
                  final e = preview[index];
                  final delay = index * 0.08;
                  final anim = CurvedAnimation(
                    parent: _stagger,
                    curve: Interval(
                      delay.clamp(0.0, 0.85),
                      1.0,
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return AnimatedBuilder(
                    animation: anim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, 20 * (1 - anim.value)),
                      child: Opacity(opacity: anim.value, child: child),
                    ),
                    child: LayoutBuilder(
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
                          onTap: () => openFortuneTypeDestination(context, e),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context, {
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        const spacing = 12.0;
        const aspect = 0.92;
        final gridHeight = ListPerf.nestedGridHeight(
          itemCount: itemCount,
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
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        );
      },
    );
  }
}
