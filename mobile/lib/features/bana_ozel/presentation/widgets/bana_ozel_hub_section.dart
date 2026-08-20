import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../fortune/presentation/widgets/premium_2026/premium_section_header.dart';
import '../../../fortune/presentation/widgets/ultra_premium/ultra_fortune_tokens.dart';
import '../../domain/entities/bana_ozel_entities.dart';
import '../navigation/bana_ozel_navigation.dart';
import '../providers/bana_ozel_providers.dart';

/// Fal & Tarot hub — Bana Özel vitrin bandı.
class BanaOzelHubSection extends ConsumerWidget {
  const BanaOzelHubSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(banaOzelCatalogProvider);
    return catalog.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.items.isEmpty) return const SizedBox.shrink();
        final preview = data.items.take(6).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: PremiumSectionHeader(
                      title: 'BANA ÖZEL',
                      icon: Icons.auto_fix_high_rounded,
                      iconColor: UltraFortuneTokens.metallicGold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => openBanaOzelCatalog(context),
                    child: const Text('Tümü'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Material(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => openBanaOzelCatalog(context),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                UltraFortuneTokens.metallicGold
                                    .withValues(alpha: 0.35),
                                UltraFortuneTokens.softLilac
                                    .withValues(alpha: 0.25),
                              ],
                            ),
                          ),
                          child: const Text('✨', style: TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sana özel fal ve tarot',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '💰 ${data.jetonBalance} jeton · ${data.items.length} içerik',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: preview.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _PreviewChip(
                    item: preview[i],
                    onTap: () => openBanaOzelCatalog(
                      context,
                      slug: preview[i].slug,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.item, required this.onTap});

  final BanaOzelItemEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 20)),
              const Spacer(),
              Text(
                item.nameTr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              Text(
                '${item.jetonCost} jeton',
                style: TextStyle(
                  fontSize: 10,
                  color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
