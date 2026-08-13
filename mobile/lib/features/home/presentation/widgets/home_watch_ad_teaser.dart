import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Reklam izle / jeton kazan teaser — `GET /api/ads/active` + büyüme merkezi.
class HomeWatchAdTeaser extends ConsumerWidget {
  const HomeWatchAdTeaser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final ads = ref.watch(homeActiveAdsProvider);
    return ads.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final reward = ref.watch(watchAdCreditProvider);
        final subtitle = reward.when(
          loading: () => 'Reklam izle, jeton kazan',
          error: (_, _) => 'Günlük reklam ödülü',
          data: (jeton) =>
              jeton > 0 ? 'Bugün +$jeton jeton kazanabilirsin' : 'Reklam izle, jeton kazan',
        );

        return Column(
          children: [
            HomeSectionTitle(
              emoji: '📺',
              title: 'Reklam İzle',
              actionLabel: 'Kazan >',
              onAction: () => context.push('/profile/growth'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HomeApprovedDesign.hPad,
              ),
              child: Material(
                color: HomeApprovedDesign.surface,
                borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
                child: InkWell(
                  onTap: () => context.push('/profile/growth'),
                  borderRadius:
                      BorderRadius.circular(HomeApprovedDesign.cardRadius),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(HomeApprovedDesign.cardRadius),
                      border: Border.all(color: HomeApprovedDesign.border),
                      gradient: LinearGradient(
                        colors: [
                          HomeApprovedDesign.gold.withValues(alpha: 0.2),
                          const Color(0xFFFF8A3D).withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: HomeApprovedDesign.gold.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_circle_rounded,
                            color: HomeApprovedDesign.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jeton Kazan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: HomeApprovedDesign.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: HomeApprovedDesign.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: HomeApprovedDesign.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
