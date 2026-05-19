import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_design.dart';
import 'discover_bottom_bar.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.bgBase,
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: DiscoverBottomBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _goBranch,
        onFabTap: () => openLiveFromFab(context),
      ),
    );
  }
}
