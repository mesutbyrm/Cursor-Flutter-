import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/bootstrap/shell_header_badges_provider.dart';
import '../../../../../core/navigation/unread_badge_format.dart';
import '../../../../../core/widgets/canlifal_logo.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../messages/presentation/providers/messages_providers.dart';
import '../../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../theme/home_approved_design.dart';

/// Onaylı mockup — logo, arama, bildirim, mesaj, jeton.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

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
              const CanlifalWordmark(fontSize: 24, compact: true),
              const Spacer(),
              const _HomeHeaderBadges(),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/search'),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: HomeApprovedDesign.searchFill.withValues(alpha: 0.85),
                borderRadius:
                    BorderRadius.circular(HomeApprovedDesign.searchRadius),
                border: Border.all(
                  color: HomeApprovedDesign.border.withValues(alpha: 0.85),
                ),
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

/// Bildirim, mesaj, jeton — anında render; cüzdan shell prefetch ile güncellenir.
class _HomeHeaderBadges extends ConsumerWidget {
  const _HomeHeaderBadges();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _DiscoverBadge(),
        SizedBox(width: 10),
        _NotificationBadge(),
        SizedBox(width: 10),
        _MessagesBadge(),
        SizedBox(width: 10),
        _HomeJetonPill(),
      ],
    );
  }
}

class _DiscoverBadge extends StatelessWidget {
  const _DiscoverBadge();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shorts'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: HomeApprovedDesign.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
          border: Border.all(
            color: HomeApprovedDesign.border.withValues(alpha: 0.9),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_rounded,
              size: 16,
              color: HomeApprovedDesign.purple.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 4),
            Text(
              'Keşfet',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: HomeApprovedDesign.textPrimary.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBadge extends ConsumerWidget {
  const _NotificationBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesReady = ref.watch(shellHeaderBadgesEnabledProvider);
    final unreadNotif =
        badgesReady ? ref.watch(notificationsUnreadCountProvider) : 0;
    return _IconBadge(
      icon: Icons.notifications_none_rounded,
      badge: unreadNotif,
      onTap: () => context.push('/notifications'),
    );
  }
}

class _MessagesBadge extends ConsumerWidget {
  const _MessagesBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesReady = ref.watch(shellHeaderBadgesEnabledProvider);
    final unreadMsg =
        badgesReady ? ref.watch(messagesUnreadCountProvider) : 0;
    return _IconBadge(
      icon: Icons.chat_bubble_outline_rounded,
      badge: unreadMsg,
      onTap: () => context.push('/messages'),
    );
  }
}

/// Rozetler — jeton oturum cache + cüzdan API.
class _HomeJetonPill extends ConsumerWidget {
  const _HomeJetonPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesReady = ref.watch(shellHeaderBadgesEnabledProvider);
    final walletJeton = badgesReady
        ? ref.watch(walletBalancesProvider.select((w) => w.valueOrNull?.jeton))
        : null;
    final authJeton = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull?.coinBalance),
    );
    final jeton = walletJeton ?? authJeton ?? 0;
    return _CoinPill(
      balance: jeton,
      onTap: () => context.push('/jeton-store'),
      onAdd: () => context.push('/jeton-store'),
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
                  UnreadBadgeFormat.label(badge),
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
          color: HomeApprovedDesign.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
          border: Border.all(
            color: HomeApprovedDesign.border.withValues(alpha: 0.9),
          ),
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
