import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/bootstrap/shell_prefetch.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/exit_confirm_dialog.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../messages/presentation/providers/messages_providers.dart';
import '../../home/presentation/widgets/fortune_teller_incoming_listener.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import 'discover_bottom_bar.dart';

class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  var _prefetched = false;

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (prev, next) {
      if (next.valueOrNull != null) {
        if (prev?.valueOrNull == null) {
          ref.invalidate(conversationsProvider);
          ref.invalidate(notificationsListProvider);
        }
        if (!_prefetched) {
          _prefetched = true;
          prefetchShellData(ref);
        }
      }
    });

    final authed = ref.watch(authControllerProvider).valueOrNull;
    if (authed != null && !_prefetched) {
      _prefetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) prefetchShellData(ref);
      });
    }

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: FortuneTellerIncomingListener(
          child: widget.navigationShell,
        ),
        extendBody: true,
        bottomNavigationBar: DiscoverBottomBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _goBranch,
          onFabTap: () => openLiveFromFab(context),
        ),
      ),
    );
  }
}
