import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state.dart';
import '../widgets.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  static const List<_ShellDestination> _destinations = <_ShellDestination>[
    _ShellDestination(
      '/home',
      'Akış',
      Icons.dynamic_feed_outlined,
      Icons.dynamic_feed,
    ),
    _ShellDestination('/live', 'Canlı', Icons.sensors_outlined, Icons.sensors),
    _ShellDestination('/chat', 'Sohbet', Icons.forum_outlined, Icons.forum),
    _ShellDestination(
      '/fortune',
      'Fal',
      Icons.auto_awesome_outlined,
      Icons.auto_awesome,
    ),
    _ShellDestination(
      '/explore',
      'Keşfet',
      Icons.travel_explore_outlined,
      Icons.travel_explore,
    ),
    _ShellDestination('/profile', 'Profil', Icons.person_outline, Icons.person),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int selectedIndex = _destinations.indexWhere(
      (_ShellDestination destination) => location.startsWith(destination.path),
    );
    final int currentIndex = selectedIndex == -1 ? 0 : selectedIndex;
    final int unreadCount = ref
        .watch(notificationsProvider)
        .maybeWhen(
          data: (List<dynamic> items) => items.length,
          orElse: () => 0,
        );

    return AnimatedGradientBackground(
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFFFF2D75), Color(0xFF7C3AED)],
                  ),
                ),
                child: const Icon(Icons.visibility, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Canlifal',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          actions: <Widget>[
            IconButton(
              tooltip: 'Admin',
              onPressed: () => context.go('/admin'),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
            Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: IconButton(
                tooltip: 'Bildirimler',
                onPressed: () => _showNotifications(context, ref),
                icon: const Icon(Icons.notifications_none),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: child,
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go('/live'),
          icon: const Icon(Icons.videocam),
          label: const Text('Yayına Katıl'),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (int index) =>
              context.go(_destinations[index].path),
          destinations: <Widget>[
            for (final _ShellDestination destination in _destinations)
              NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, WidgetRef ref) {
    final Object value = ref.read(notificationsProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF11111D),
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SectionHeader(
                title: 'Bildirimler',
                subtitle: 'Canlı yayın, FanClub ve sistem uyarıları',
              ),
              if (value is AsyncData)
                for (final dynamic item in value.value)
                  ListTile(
                    leading: Text(
                      item.icon,
                      style: const TextStyle(fontSize: 26),
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.body),
                    trailing: Text(item.createdLabel),
                  )
              else
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ShellDestination {
  const _ShellDestination(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
