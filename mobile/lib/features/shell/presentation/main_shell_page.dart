import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/bootstrap/shell_prefetch.dart';
import '../../../core/bootstrap/stuck_overlay_guard.dart';
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
  Timer? _overlayScrubTimer;
  var _overlayScrubTicks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _clearStuckOverlays('mount'));
    _armOverlayScrub();
  }

  @override
  void dispose() {
    _overlayScrubTimer?.cancel();
    super.dispose();
  }

  void _armOverlayScrub() {
    _overlayScrubTimer?.cancel();
    _overlayScrubTicks = 0;
    _overlayScrubTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _overlayScrubTicks >= 48) {
        _overlayScrubTimer?.cancel();
        return;
      }
      _overlayScrubTicks++;
      _clearStuckOverlays('scrub-$_overlayScrubTicks');
    });
  }

  void _clearStuckOverlays(String reason) {
    if (!mounted) return;
    final nested = Navigator.maybeOf(context);
    StuckOverlayGuard.dismissAll(reason: 'main-shell-$reason', nested: nested);
  }

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
            if (context.mounted) context.go('/login');
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
