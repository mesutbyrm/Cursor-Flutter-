import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../fortune/presentation/data/fortune_catalog.dart';
import '../../../platform/data/models/fortune_request_type.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import '../theme/home_premium_design.dart';
import 'approved/home_section_title.dart';
import 'premium_2026/home_horizontal_list.dart';
import '../../../../../core/ui/premium/premium_skeleton.dart';

/// Canlı fal türleri — `GET /api/fortune-request-types`.
class HomeFortuneRequestTypesSection extends ConsumerWidget {
  const HomeFortuneRequestTypesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(homeFortuneRequestTypesProvider);
    return types.when(
      loading: () => Column(
        children: [
          HomeSectionTitle(
            emoji: '✨',
            title: 'Fal Türleri',
            actionLabel: 'Fal >',
            onAction: () => context.push('/fortune/types'),
          ),
          HomeHorizontalList(
            height: 112,
            itemCount: 4,
            itemBuilder: (_, _) => const PremiumSkeleton(
              width: 120,
              height: 112,
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
            title: 'Fal Türleri',
            actionLabel: 'Fal >',
            onAction: () => context.push('/fortune/types'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeApprovedDesign.hPad,
            ),
            child: TextButton(
              onPressed: () => ref.invalidate(homeFortuneRequestTypesProvider),
              child: const Text('Yüklenemedi — Tekrar dene'),
            ),
          ),
        ],
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '✨',
              title: 'Fal Türleri',
              actionLabel: 'Fal >',
              onAction: () => context.push('/fortune/types'),
            ),
            HomeHorizontalList(
              height: 112,
              itemCount: items.length,
              itemBuilder: (_, i) => _TypeCard(type: items[i]),
            ),
          ],
        );
      },
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type});

  final FortuneRequestType type;

  String get _routeSlug {
    final catalog = FortuneCatalog.bySlug(type.key);
    return catalog?.slug ?? type.key;
  }

  @override
  Widget build(BuildContext context) {
    final cost = type.jetonCost;
    final catalog = FortuneCatalog.bySlug(type.key);
    final accent = catalog?.accent ?? HomeApprovedDesign.purple;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/fortune/$_routeSlug'),
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Ink(
          width: 120,
          decoration: HomePremiumDesign.glassCard(
            tint: HomePremiumDesign.surface,
            radius: HomeApprovedDesign.cardRadius,
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: accent,
              ),
              const Spacer(),
              Text(
                type.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: HomeApprovedDesign.textPrimary,
                  height: 1.15,
                ),
              ),
              if (cost != null && cost > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '$cost jeton',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: HomeApprovedDesign.gold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
