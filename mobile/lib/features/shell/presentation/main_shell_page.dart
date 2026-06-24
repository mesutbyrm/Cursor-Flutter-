import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/bootstrap/shell_prefetch.dart';
import '../../../core/widgets/exit_confirm_dialog.dart';
import 'shell_ui.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../messages/presentation/providers/messages_providers.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../../home/presentation/widgets/approved/bottom_navigation_widget.dart';

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

  HomeBottomTab _activeTab(int shellIndex) {
    switch (shellIndex) {
      case 0:
        return HomeBottomTab.home;
      case 1:
        return HomeBottomTab.social;
      case 2:
        return HomeBottomTab.live;
      case 3:
        return HomeBottomTab.home;
      case 4:
        return HomeBottomTab.profile;
      default:
        return HomeBottomTab.home;
    }
  }

  void _onYayinTap(BuildContext context) {
    if (widget.navigationShell.currentIndex == 2) {
      ShellUi.showCreateSheet(context, GoRouter.of(context));
      return;
    }
    _goBranch(2);
  }

  void _onYayinLongPress(BuildContext context) {
    ShellUi.showCreateSheet(context, GoRouter.of(context));
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
          },
        );
      },
      child: Scaffold(
        backgroundColor: ShellUi.shellBackground(context),
        body: widget.navigationShell,
        bottomNavigationBar: BottomNavigationWidget(
          activeTab: _activeTab(widget.navigationShell.currentIndex),
          onHome: () => _goBranch(0),
          onSocial: () => _goBranch(1),
          onCreate: () => _onYayinTap(context),
          onCreateLongPress: () => _onYayinLongPress(context),
          onJeton: () => context.push('/jeton-store'),
          onProfile: () => _goBranch(4),
        ),
      ),
    );
  }
}
