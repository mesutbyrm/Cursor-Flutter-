import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Davet ödülü teaser — `GET /api/referral` + `/invite-friends`.
class HomeInviteReferralTeaser extends ConsumerWidget {
  const HomeInviteReferralTeaser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final referral = ref.watch(referralInfoProvider);
    return referral.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (info) {
        final invited = info.invitedCount ?? 0;
        final subtitle = info.rewardHint?.trim().isNotEmpty == true
            ? info.rewardHint!
            : invited > 0
                ? '$invited arkadaş davet edildi'
                : 'Arkadaşlarını davet et, jeton kazan';

        return Column(
          children: [
            HomeSectionTitle(
              emoji: '🎁',
              title: 'Arkadaşını Davet Et',
              actionLabel: 'Paylaş >',
              onAction: () => context.push('/invite-friends'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HomeApprovedDesign.hPad,
              ),
              child: Material(
                color: HomeApprovedDesign.surface,
                borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
                child: InkWell(
                  onTap: () => context.push('/invite-friends'),
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
                          const Color(0xFF06B6D4).withValues(alpha: 0.18),
                          HomeApprovedDesign.purple.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.group_add_rounded,
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.headline?.trim().isNotEmpty == true
                                    ? info.headline!
                                    : 'Davet kodunla kazan',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: HomeApprovedDesign.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
