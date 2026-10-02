import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/bootstrap/root_overlay_purge.dart';
import '../../../core/bootstrap/shell_prefetch.dart';
import '../../../core/widgets/exit_confirm_dialog.dart';
import 'shell_ui.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../messages/presentation/providers/messages_providers.dart';
import '../../notifications/presentation/providers/notification_event_gate_provider.dart';
import '../../home/presentation/widgets/approved/bottom_navigation_widget.dart';

class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  var _prefetched = false;
  int? _lastBranchIndex;

  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    _schedulePurgeIfBlocked('branch-switch-$index');
  }

  void _schedulePurgeIfBlocked(String reason) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RootOverlayPurge.purgeIfBlocked(reason: reason);
    });
  }

  HomeBottomTab _activeTab(BuildContext context, int shellIndex) {
    if (shellIndex == 3) {
      final type = GoRouterState.of(context).uri.queryParameters['type'];
      if (type == 'tarot') return HomeBottomTab.fortuneTarot;
      return HomeBottomTab.fortuneTarot;
    }
    switch (shellIndex) {
      case 0:
        return HomeBottomTab.home;
      case 1:
        return HomeBottomTab.social;
      case 2:
        return HomeBottomTab.voice;
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
          ref.read(notificationEventGateProvider).markSessionStart();
          ref.invalidate(conversationsProvider);
        }
        if (!_prefetched) {
          _prefetched = true;
          prefetchShellData(ref);
        }
      }
    });

    final currentIndex = widget.navigationShell.currentIndex;
    if (_lastBranchIndex != currentIndex) {
      _lastBranchIndex = currentIndex;
      _schedulePurgeIfBlocked('branch-active-$currentIndex');
    }

    final authed = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull),
    );
    if (authed != null && !_prefetched) {
      _prefetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) prefetchShellData(ref);
      });
    }

    final router = GoRouter.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (router.canPop()) {
          context.pop();
          return;
        }
        await handleShellBackPress(context);
      },
      child: Scaffold(
        backgroundColor: ShellUi.shellBackground(context),
        body: widget.navigationShell,
        bottomNavigationBar: BottomNavigationWidget(
          activeTab: _activeTab(context, widget.navigationShell.currentIndex),
          onHome: () => _goBranch(0),
          onSocial: () => _goBranch(1),
          onVoice: () => context.go('/voice-rooms'),
          onCreate: () => ShellUi.showPublishNavSheet(context, router),
          onFortuneTarot: () => context.go('/fortune'),
          onMeet: () => context.push('/social/tanis-kaynas'),
          onProfile: () => _goBranch(4),
        ),
      ),
    );
  }
}
