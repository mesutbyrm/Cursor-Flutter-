import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../platform/data/models/fortune_request_type.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Canlı fal türleri — `GET /api/fortune-request-types`.
class HomeFortuneRequestTypesSection extends ConsumerWidget {
  const HomeFortuneRequestTypesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(homeFortuneRequestTypesProvider);
    return types.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '✨',
              title: 'Fal Türleri',
              actionLabel: 'Fal >',
              onAction: () => context.go('/fortune'),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _TypeChip(type: items[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final FortuneRequestType type;

  @override
  Widget build(BuildContext context) {
    final cost = type.jetonCost;
    final subtitle = cost != null && cost > 0 ? '$cost jeton' : null;

    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
      child: InkWell(
        onTap: () => context.push('/fortune/${type.key}'),
        borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
            border: Border.all(color: HomeApprovedDesign.border),
            gradient: LinearGradient(
              colors: [
                HomeApprovedDesign.purple.withValues(alpha: 0.16),
                HomeApprovedDesign.surface,
              ],
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: HomeApprovedDesign.purple,
              ),
              const SizedBox(width: 6),
              Text(
                type.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: HomeApprovedDesign.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 6),
                Text(
                  subtitle,
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
