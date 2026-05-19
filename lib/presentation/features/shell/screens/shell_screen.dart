import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_mobile/presentation/providers/providers.dart';
import 'package:canlifal_mobile/presentation/widgets/shared_widgets.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  static const List<_ShellDestination> _destinations = <_ShellDestination>[
    _ShellDestination('/home', 'Keşfet', Icons.explore_outlined, Icons.explore),
    _ShellDestination(
      '/explore',
      'Sosyal',
      Icons.language_outlined,
      Icons.language,
    ),
    _ShellDestination('/live', '', Icons.camera_alt, Icons.camera_alt),
    _ShellDestination(
      '/fortune',
      'Jeton AI',
      Icons.generating_tokens_outlined,
      Icons.generating_tokens,
    ),
    _ShellDestination(
      '/profile',
      'Fan Club',
      Icons.favorite_border,
      Icons.favorite,
    ),
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
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: _TopDock(
                  unreadCount: unreadCount,
                  onNotifications: () => _showNotifications(context, ref),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: child,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 78),
          child: FloatingActionButton(
            heroTag: 'quick-actions',
            onPressed: () => _showQuickActions(context),
            backgroundColor: const Color(0xFFD52DFF),
            child: const Icon(Icons.menu, size: 30),
          ),
        ),
        bottomNavigationBar: _BottomDock(
          destinations: _destinations,
          selectedIndex: currentIndex,
          onSelected: (int index) {
            if (index == 2) {
              context.go('/live/create');
            } else {
              context.go(_destinations[index].path);
            }
          },
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
              decoration: BoxDecoration(
                color: const Color(0xFF12001F).withValues(alpha: .94),
                border: Border.all(
                  color: const Color(0xFFB832FF).withValues(alpha: .35),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Hızlı İşlemler',
                        style: CanlifalText.sectionTitle(context),
                      ),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: <Widget>[
                      _QuickTile(
                        icon: '🏆',
                        label: 'Futbol',
                        onTap: () => context.go('/explore'),
                      ),
                      _QuickTile(
                        icon: '▶️',
                        label: 'Dizi & Film',
                        onTap: () => context.go('/explore'),
                      ),
                      _QuickTile(
                        icon: '🎮',
                        label: 'Oyunlar',
                        onTap: () => context.go('/explore'),
                      ),
                      _QuickTile(
                        icon: '👥',
                        label: 'Davet Et',
                        onTap: () => context.go('/profile'),
                      ),
                      _QuickTile(
                        icon: '🎁',
                        label: 'Hediye',
                        onTap: () => context.go('/live'),
                      ),
                      _QuickTile(
                        icon: '⚡',
                        label: 'Bana Özel',
                        onTap: () => context.go('/fortune'),
                      ),
                      _QuickTile(
                        icon: '👑',
                        label: 'Premium',
                        onTap: () => context.go('/profile'),
                      ),
                      _QuickTile(
                        icon: '⭐',
                        label: 'Ünlüler',
                        onTap: () => context.go('/explore'),
                      ),
                      _QuickTile(
                        icon: '📈',
                        label: 'Trendler',
                        onTap: () => context.go('/home'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

class _TopDock extends StatelessWidget {
  const _TopDock({required this.unreadCount, required this.onNotifications});

  final int unreadCount;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _TopDockItem(
            icon: Icons.person,
            label: 'Profil',
            onTap: () => context.go('/profile'),
            avatar: true,
          ),
          _TopDockItem(
            icon: Icons.chat_bubble_outline,
            label: 'Mesajlar',
            onTap: () => context.go('/chat'),
          ),
          _TopDockItem(
            icon: Icons.notifications_none,
            label: 'Bildirim',
            badge: unreadCount,
            onTap: onNotifications,
          ),
          _TopDockItem(
            icon: Icons.auto_awesome,
            label: 'Admin Paneli',
            onTap: () => context.go('/admin'),
          ),
        ],
      ),
    );
  }
}

class _TopDockItem extends StatelessWidget {
  const _TopDockItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.avatar = false,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool avatar;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: avatar
                  ? const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFF32104B),
                      child: Text(
                        'ADMIN',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : Icon(icon, color: const Color(0xFFCBA6FF), size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFCBA6FF),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              for (int i = 0; i < destinations.length; i++)
                _BottomDockItem(
                  destination: destinations[i],
                  selected: selectedIndex == i,
                  isCenter: i == 2,
                  onTap: () => onSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomDockItem extends StatelessWidget {
  const _BottomDockItem({
    required this.destination,
    required this.selected,
    required this.isCenter,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final bool isCenter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (isCenter) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFFFF4EC8), Color(0xFFD52DFF)],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFFFF4EC8).withValues(alpha: .55),
                blurRadius: 24,
              ),
            ],
          ),
          child: Icon(destination.selectedIcon, size: 34),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              color: selected
                  ? const Color(0xFFFF72E0)
                  : const Color(0xFFCBA6FF),
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? const Color(0xFFFF72E0)
                    : const Color(0xFFCBA6FF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
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
