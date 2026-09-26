import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/bootstrap/shell_header_badges_provider.dart';
import '../../../../../core/motion/canlifal_motion_widgets.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/widgets/canlifal_logo.dart';
import '../../../../inbox/presentation/inbox_routes.dart';
import '../../../../inbox/presentation/providers/inbox_unread_providers.dart';
import '../../theme/home_approved_design.dart';
import 'home_header_balance_chips.dart';
import '../home_motion_widgets.dart';

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
          const _HomeSearchBar(),
        ],
      ),
    );
  }
}

/// Arama girişi — dokununca arama sayfasını açar.
class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkTheme;
    final colors = context.colors;
    final muted = colors.onSurfaceMuted;
    return Semantics(
      button: true,
      label: 'Ara',
      onTap: () => context.push('/search'),
      excludeSemantics: true,
      child: CanlifalPressable(
        scale: 0.98,
        onTap: () => context.push('/search'),
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: dark ? HomeApprovedDesign.searchFill : colors.surface,
            borderRadius: BorderRadius.circular(
              HomeApprovedDesign.searchRadius,
            ),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.07)
                  : colors.outlineVariant,
            ),
            boxShadow: dark ? null : colors.cardShadow,
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, size: 21, color: muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kişi, oda veya içerik ara...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: muted,
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
