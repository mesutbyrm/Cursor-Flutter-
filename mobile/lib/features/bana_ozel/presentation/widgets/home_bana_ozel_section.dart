import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/theme/home_approved_design.dart';
import '../../../home/presentation/theme/home_premium_design.dart';
import '../../../home/presentation/widgets/approved/home_section_title.dart';
import '../../../home/presentation/widgets/premium_2026/home_horizontal_list.dart';
import '../../domain/entities/bana_ozel_entities.dart';
import '../navigation/bana_ozel_navigation.dart';
import '../providers/bana_ozel_providers.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';

/// Ana sayfa — Bana Özel yatay vitrin (`GET /api/bana-ozel`).
class HomeBanaOzelSection extends ConsumerWidget {
  const HomeBanaOzelSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(banaOzelCatalogProvider);
    return catalog.when(
      loading: () => Column(
        children: [
          HomeSectionTitle(
            emoji: '✨',
            title: 'Bana Özel',
            actionLabel: 'Tümü >',
            onAction: () => openBanaOzelCatalog(context),
          ),
          HomeHorizontalList(
            height: 118,
            itemCount: 3,
            itemBuilder: (_, _) => const PremiumSkeleton(
              width: 132,
              height: 118,
              borderRadius: BorderRadius.all(
                Radius.circular(HomeApprovedDesign.cardRadius),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => Column(
        children: [
          HomeSectionTitle(
            emoji: '✨',
            title: 'Bana Özel',
            actionLabel: 'Tümü >',
            onAction: () => openBanaOzelCatalog(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeApprovedDesign.hPad,
            ),
            child: TextButton(
              onPressed: () => ref.invalidate(banaOzelCatalogProvider),
              child: const Text('Yüklenemedi — Tekrar dene'),
            ),
          ),
        ],
      ),
      data: (data) {
        if (data.items.isEmpty) return const SizedBox.shrink();
        final preview = data.items.take(8).toList();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '✨',
              title: 'Bana Özel',
              actionLabel: 'Tümü >',
              onAction: () => openBanaOzelCatalog(context),
            ),
            HomeHorizontalList(
              height: 118,
              itemCount: preview.length,
              itemBuilder: (_, i) => _Card(
                item: preview[i],
                balance: data.jetonBalance,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.item, required this.balance});

  final BanaOzelItemEntity item;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final affordable = balance >= item.jetonCost;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openBanaOzelCatalog(context, slug: item.slug),
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Ink(
          width: 132,
          padding: const EdgeInsets.all(12),
          decoration: HomePremiumDesign.glassCard(
            tint: HomePremiumDesign.surface,
            radius: HomeApprovedDesign.cardRadius,
            border: Border.all(
              color: HomeApprovedDesign.purple.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 22)),
              const Spacer(),
              Text(
                item.nameTr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: HomeApprovedDesign.textPrimary,
                ),
              ),
              if (item.descTr != null && item.descTr!.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.descTr!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: HomeApprovedDesign.textMuted.withValues(alpha: 0.95),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                '${item.jetonCost} jeton',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: affordable
                      ? HomeApprovedDesign.purple
                      : HomeApprovedDesign.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
