import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/canlifal_brand_logo.dart';
import '../../../../messages/presentation/providers/messages_providers.dart';
import '../../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../theme/home_approved_design.dart';

/// Onaylı mockup — logo, arama, bildirim, mesaj, jeton.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final unreadNotif = ref.watch(notificationsUnreadCountProvider);
    final unreadMsg = ref.watch(messagesUnreadCountProvider);
    final jeton = ref.watch(walletBalancesProvider).valueOrNull?.jeton ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        top + 8,
        HomeApprovedDesign.hPad,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CanlifalBrandLogo.horizontal(height: 28),
              const Spacer(),
              _IconBadge(
                icon: Icons.notifications_none_rounded,
                badge: unreadNotif,
                onTap: () => context.push('/notifications'),
              ),
              const SizedBox(width: 10),
              _IconBadge(
                icon: Icons.chat_bubble_outline_rounded,
                badge: unreadMsg,
                onTap: () => context.push('/messages'),
              ),
              const SizedBox(width: 10),
              _CoinPill(
                balance: jeton,
                onTap: () => context.push('/jeton-store'),
                onAdd: () => context.push('/jeton-store'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/search'),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: HomeApprovedDesign.searchFill,
                borderRadius:
                    BorderRadius.circular(HomeApprovedDesign.searchRadius),
                border: Border.all(color: HomeApprovedDesign.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: HomeApprovedDesign.textMuted.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Kişi, oda veya içerik ara...',
                    style: TextStyle(
                      fontSize: 14,
                      color: HomeApprovedDesign.textMuted.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 24, color: HomeApprovedDesign.textPrimary),
          if (badge > 0)
            Positioned(
              right: -5,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: HomeApprovedDesign.liveRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({
    required this.balance,
    required this.onTap,
    required this.onAdd,
  });

  final int balance;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.only(left: 8, right: 4),
        decoration: BoxDecoration(
          color: HomeApprovedDesign.surface,
          borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
          border: Border.all(color: HomeApprovedDesign.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.monetization_on_rounded,
              size: 18,
              color: HomeApprovedDesign.gold,
            ),
            const SizedBox(width: 4),
            Text(
              _formatBalance(balance),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: HomeApprovedDesign.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: HomeApprovedDesign.purple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatBalance(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
