import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/home_approved_design.dart';

/// Referans mockup — Keşfet / Canlı / Sesli / Fal / Tanış yatay chip’leri.
class HomeCategoryChips extends StatelessWidget {
  const HomeCategoryChips({super.key});

  static const _items = <_ChipItem>[
    _ChipItem(label: 'Keşfet', route: '/feed', icon: Icons.explore_rounded),
    _ChipItem(label: 'Canlı', route: '/live', icon: Icons.videocam_rounded),
    _ChipItem(label: 'Sesli', route: '/voice-rooms', icon: Icons.mic_rounded),
    _ChipItem(label: 'Fal', route: '/fortune', icon: Icons.auto_awesome_rounded),
    _ChipItem(
      label: 'Tanış',
      route: '/social/tanis-kaynas',
      icon: Icons.favorite_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = _items[i];
          final active = _isActive(path, item);
          return _CategoryChip(
            item: item,
            active: active,
            onTap: () {
              if (item.route == '/feed') {
                context.go('/feed');
              } else {
                context.push(item.route);
              }
            },
          );
        },
      ),
    );
  }

  static bool _isActive(String path, _ChipItem item) {
    if (item.route == '/feed') {
      return path == '/feed' || path == '/';
    }
    return path.startsWith(item.route);
  }
}

class _ChipItem {
  const _ChipItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _ChipItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.pillRadius),
            gradient: active
                ? LinearGradient(
                    colors: [
                      HomeApprovedDesign.purple.withValues(alpha: 0.95),
                      HomeApprovedDesign.pink.withValues(alpha: 0.75),
                    ],
                  )
                : null,
            color: active
                ? null
                : HomeApprovedDesign.surface.withValues(alpha: 0.72),
            border: Border.all(
              color: active
                  ? HomeApprovedDesign.purple.withValues(alpha: 0.5)
                  : HomeApprovedDesign.border.withValues(alpha: 0.85),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: HomeApprovedDesign.purple.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 16,
                color: active
                    ? Colors.white
                    : HomeApprovedDesign.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: active
                      ? Colors.white
                      : HomeApprovedDesign.textPrimary.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
