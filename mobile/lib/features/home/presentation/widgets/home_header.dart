import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../theme/home_palette.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final name = user?.display ?? 'CanlıFal';
    final coins = ref.watch(coinBalanceProvider).valueOrNull ??
        user?.coinBalance ??
        0;
    final coinLabel = NumberFormat.decimalPattern('tr').format(coins);
    final unread = ref.watch(notificationsUnreadCountProvider);
    final vip = ref.watch(vipTierProvider).index >= VipTier.gold.index;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 8,
            16,
            12,
          ),
          decoration: BoxDecoration(
            color: HomePalette.darkBackground.withValues(alpha: 0.72),
            border: Border(
              bottom: BorderSide(
                color: context.colors.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [HomePalette.primary, HomePalette.secondary],
                        ),
                      ),
                      child: UserAvatar(url: user?.avatarUrl, radius: 22),
                    ),
                    if (vip)
                      const Positioned(
                        right: -2,
                        top: -2,
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 18,
                          color: HomePalette.accentGold,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş geldin,',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: context.colors.onSurface,
                            ),
                          ),
                        ),
                        if (vip) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  HomePalette.primary,
                                  HomePalette.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                HomePalette.radiusPill,
                              ),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _CoinChip(label: coinLabel, onTap: () => context.push('/jeton-store')),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => context.push('/fortune/gunluk-fal'),
                icon: const Icon(
                  Icons.card_giftcard_rounded,
                  color: HomePalette.accentGold,
                ),
                tooltip: 'Günlük ödül',
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => context.push('/notifications'),
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      color: context.colors.onSurface,
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B5C),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomePalette.radiusPill),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: HomePalette.glassFill,
            borderRadius: BorderRadius.circular(HomePalette.radiusPill),
            border: Border.all(color: HomePalette.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                size: 18,
                color: HomePalette.accentGold,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: HomePalette.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
