import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/inbox/presentation/inbox_routes.dart';
import '../../features/inbox/presentation/providers/inbox_unread_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import 'dual_balance_chips.dart';
import 'user_avatar.dart';

/// Profil sekmesi gibi yerlerde: ana akışa (`/feed`) döner.
class ShellFeedLeading extends StatelessWidget {
  const ShellFeedLeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        tooltip: 'Ana akış',
        onPressed: () => context.go('/feed'),
        icon: const Icon(Icons.home_rounded),
      ),
    );
  }
}

/// Alt shell’deki Profil sekmesine (`/profile`) gider.
class ShellProfileLeading extends ConsumerWidget {
  const ShellProfileLeading({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: auth.when(
        data: (user) {
          if (user == null) {
            return IconButton(
              tooltip: 'Profil',
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.person_rounded),
            );
          }
          return IconButton(
            tooltip: 'Profilim',
            padding: EdgeInsets.zero,
            onPressed: () => context.go('/profile'),
            icon: UserAvatar(url: user.avatarUrl, radius: 18),
          );
        },
        loading: () => IconButton(
          tooltip: 'Profil',
          onPressed: () => context.go('/profile'),
          icon: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (e, s) => IconButton(
          tooltip: 'Profil',
          onPressed: () => context.go('/profile'),
          icon: const Icon(Icons.person_rounded),
        ),
      ),
    );
  }
}

class ShellInboxButton extends ConsumerWidget {
  const ShellInboxButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(inboxUnreadCountProvider);
    return IconButton(
      tooltip: 'Gelen kutusu',
      onPressed: () => InboxRoutes.open(context),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.inbox_rounded),
      ),
    );
  }
}

/// Geriye dönük uyumluluk.
class ShellNotificationsButton extends ShellInboxButton {
  const ShellNotificationsButton({super.key});
}

/// Jeton bakiyesi; dokununca jeton mağazası.
class ShellCoinBalanceAction extends ConsumerWidget {
  const ShellCoinBalanceAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletBalancesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: wallet.when(
        data: (b) => DualBalanceChips(
          jeton: b.jeton,
          cfc: b.cfc,
          compact: true,
        ),
        loading: () => const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, _) => Tooltip(
          message: 'Jeton yükle',
          child: InkWell(
            onTap: () => context.push('/jeton-store'),
            child: const Icon(Icons.monetization_on_rounded, size: 22),
          ),
        ),
      ),
    );
  }
}
