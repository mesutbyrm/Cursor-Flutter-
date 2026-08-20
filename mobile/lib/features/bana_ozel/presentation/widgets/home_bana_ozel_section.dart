import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/theme/home_approved_design.dart';
import '../../../home/presentation/widgets/approved/home_section_title.dart';
import '../../domain/entities/bana_ozel_entities.dart';
import '../navigation/bana_ozel_navigation.dart';
import '../providers/bana_ozel_providers.dart';

/// Ana sayfa — Bana Özel yatay vitrin (`GET /api/bana-ozel`).
class HomeBanaOzelSection extends ConsumerWidget {
  const HomeBanaOzelSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(banaOzelCatalogProvider);
    return catalog.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                itemCount: preview.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _Card(
                  item: preview[i],
                  balance: data.jetonBalance,
                ),
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
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
      child: InkWell(
        onTap: () => openBanaOzelCatalog(context, slug: item.slug),
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Container(
          width: 132,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            border: Border.all(color: HomeApprovedDesign.border),
            gradient: LinearGradient(
              colors: [
                HomeApprovedDesign.purple.withValues(alpha: 0.2),
                HomeApprovedDesign.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
