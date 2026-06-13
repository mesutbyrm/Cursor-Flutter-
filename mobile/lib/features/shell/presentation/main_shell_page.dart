import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/bootstrap/shell_prefetch.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/exit_confirm_dialog.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../messages/presentation/providers/messages_providers.dart';
import '../../notifications/presentation/providers/notifications_providers.dart';
import '../../home/presentation/theme/home_approved_design.dart';
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
      case 2:
        return HomeBottomTab.live;
      case 4:
        return HomeBottomTab.profile;
      default:
        return HomeBottomTab.home;
    }
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
        backgroundColor: HomeApprovedDesign.background,
        body: widget.navigationShell,
        bottomNavigationBar: BottomNavigationWidget(
          activeTab: _activeTab(widget.navigationShell.currentIndex),
          onHome: () => _goBranch(0),
          onLive: () => _goBranch(2),
          onRooms: () => context.push('/voice-rooms'),
          onJeton: () => context.push('/jeton-store'),
          onProfile: () => _goBranch(4),
        ),
      ),
    );
  }
}
