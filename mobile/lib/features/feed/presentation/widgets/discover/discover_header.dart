import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/canlifal_tokens.dart';
import '../../../../../core/ui/premium/premium.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';

class DiscoverHeader extends ConsumerWidget {
  const DiscoverHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final name = user?.display ?? 'Misafir';
    final coins = ref.watch(coinBalanceProvider).valueOrNull ??
        user?.coinBalance ??
        0;
    final coinLabel = NumberFormat.decimalPattern('tr').format(coins);
    final unreadNotifications = ref.watch(notificationsUnreadCountProvider);
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/profile'),
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: tokens.brandGradient,
                  boxShadow:
                      AppColors.glowShadow(AppColors.accentPurple, blur: 16),
                ),
                child: UserAvatar(url: user?.avatarUrl, radius: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş geldin',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          size: 20,
                          color: AppColors.accentPurple.withValues(alpha: 0.95),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          PremiumCoinCapsule(
            label: coinLabel,
            onTap: () => context.push('/jeton-store'),
          ),
          const SizedBox(width: 10),
          PremiumIconButton(
            icon: Icons.notifications_none_rounded,
            showBadge: unreadNotifications > 0,
            badgeCount: unreadNotifications,
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }
}
