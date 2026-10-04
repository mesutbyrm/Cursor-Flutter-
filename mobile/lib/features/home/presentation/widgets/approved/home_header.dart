import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/bootstrap/shell_header_badges_provider.dart';
import '../../../../../core/widgets/canlifal_logo.dart';
import '../../../../inbox/presentation/inbox_routes.dart';
import '../../../../inbox/presentation/providers/inbox_unread_providers.dart';
import '../../theme/home_approved_design.dart';
import 'home_header_balance_chips.dart';
import '../home_motion_widgets.dart';

/// Onaylı mockup — GirLive logosu, mesaj, jeton.
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
              const GirLiveWordmark(fontSize: 24),
              const Spacer(),
              const _HomeHeaderBadges(),
            ],
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
        _UnifiedInboxBadge(),
        SizedBox(width: 8),
        _HomeBalanceChips(),
      ],
    );
  }
}

/// Mesaj + sistem bildirimi — tek gelen kutusu girişi.
class _UnifiedInboxBadge extends ConsumerWidget {
  const _UnifiedInboxBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesReady = ref.watch(shellHeaderBadgesEnabledProvider);
    final unreadInbox = badgesReady ? ref.watch(inboxUnreadCountProvider) : 0;
    return HomePulsingIconBadge(
      icon: Icons.mail_rounded,
      badge: unreadInbox,
      onTap: () => InboxRoutes.open(context),
    );
  }
}

/// Rozetler — jeton + CFC (markalı, kompakt).
class _HomeBalanceChips extends StatelessWidget {
  const _HomeBalanceChips();

  @override
  Widget build(BuildContext context) {
    return const HomeHeaderBalanceChips();
  }
}
