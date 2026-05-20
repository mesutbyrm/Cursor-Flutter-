import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_design.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
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
                  gradient: AppDesign.heroGradient,
                  boxShadow:
                      AppDesign.glowShadow(AppDesign.accentPurple, blur: 16),
                ),
                child: UserAvatar(url: user?.avatarUrl, radius: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
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
                        style: TextStyle(
                          fontSize: 13,
                          color: AppDesign.textSecondary.withValues(alpha: 0.9),
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
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppDesign.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.verified_rounded,
                            size: 20,
                            color:
                                AppDesign.accentPurple.withValues(alpha: 0.95),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _CoinCapsule(
            label: coinLabel,
            onTap: () => context.push('/jeton-store'),
          ),
          const SizedBox(width: 10),
          _NotificationButton(
            onTap: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }
}

class _CoinCapsule extends StatelessWidget {
  const _CoinCapsule({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: AppDesign.coinCapsuleGradient,
            border: Border.all(
              color: AppDesign.accentPurple.withValues(alpha: 0.45),
            ),
            boxShadow: AppDesign.glowShadow(
              AppDesign.accentPurple,
              blur: 14,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF7DD3FC), Color(0xFFC084FC)],
                ).createShader(b),
                child: const Icon(
                  Icons.diamond_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppDesign.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: AppDesign.textSecondary.withValues(alpha: 0.95),
                size: 26,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppDesign.liveRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppDesign.bgBase, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
