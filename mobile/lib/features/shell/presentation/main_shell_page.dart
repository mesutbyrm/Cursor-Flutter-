import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/exit_confirm_dialog.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../messages/presentation/providers/messages_providers.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import 'discover_bottom_bar.dart';

class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (prev, next) {
      if (next.valueOrNull != null && prev?.valueOrNull == null) {
        ref.invalidate(conversationsProvider);
        ref.invalidate(notificationsListProvider);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (GoRouter.of(context).canPop()) {
          context.pop();
          return;
        }
        await handleShellBackPress(
          context,
          onLogout: () async {
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: navigationShell,
        extendBody: true,
        bottomNavigationBar: DiscoverBottomBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _goBranch,
          onFabTap: () => openLiveFromFab(context),
        ),
      ),
    );
  }
}
