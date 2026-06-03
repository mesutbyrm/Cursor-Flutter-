import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/ui/premium/premium.dart';
import 'discover_premium_visual.dart';
import '../../../../../core/widgets/messages_notifications_actions.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';

/// Blur üst bar — profil + jeton + bildirimler.
class DiscoverPremiumHeader extends ConsumerWidget {
  const DiscoverPremiumHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final guest = ref.watch(guestModeProvider);
    final name = user?.display ?? (guest ? 'Misafir' : 'CanlıFal');
    final coins = ref.watch(coinBalanceProvider).valueOrNull ??
        user?.coinBalance ??
        0;
    final coinLabel = NumberFormat.decimalPattern('tr').format(coins);

    return RepaintBoundary(
      child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: DiscoverPremiumVisual.glassBlur,
          sigmaY: DiscoverPremiumVisual.glassBlur,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
          decoration: BoxDecoration(
            color: DiscoverPremiumVisual.glassFill,
            border: Border(
              bottom: BorderSide(
                color: DiscoverPremiumVisual.glassBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/profile'),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: DiscoverPremiumVisual.brandGradient,
                    boxShadow: DiscoverPremiumVisual.cardGlow(),
                  ),
                  child: UserAvatar(url: user?.avatarUrl, radius: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keşfet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              PremiumCoinCapsule(
                label: coinLabel,
                onTap: () => context.push('/jeton-store'),
              ),
              const SizedBox(width: 4),
              const MessagesNotificationsActions(),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
