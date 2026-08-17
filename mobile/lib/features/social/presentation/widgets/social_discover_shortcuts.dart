import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../utils/social_discover_shortcut_labels.dart';

/// Sosyal sekme keşif kısayolları — ünlüler, fan kulüp, canlı ve sesli odalar.
class SocialDiscoverShortcuts extends StatelessWidget {
  const SocialDiscoverShortcuts({super.key});

  static final _items = [
    _ShortcutItem(
      icon: Icons.star_rounded,
      label: socialDiscoverShortcutLabels[0],
      route: socialDiscoverShortcutRoutes[0],
      color: AppThemeColors.coinGold,
    ),
    _ShortcutItem(
      icon: Icons.favorite_rounded,
      label: socialDiscoverShortcutLabels[1],
      route: socialDiscoverShortcutRoutes[1],
      color: AppThemeColors.accentPink,
    ),
    _ShortcutItem(
      icon: Icons.live_tv_rounded,
      label: socialDiscoverShortcutLabels[2],
      route: socialDiscoverShortcutRoutes[2],
      color: AppThemeColors.liveRed,
    ),
    _ShortcutItem(
      icon: Icons.mic_rounded,
      label: socialDiscoverShortcutLabels[3],
      route: socialDiscoverShortcutRoutes[3],
      color: AppThemeColors.accentPurple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ActionChip(
            avatar: Icon(item.icon, size: 16, color: item.color),
            label: Text(
              item.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
            backgroundColor: item.color.withValues(alpha: 0.14),
            side: BorderSide(color: item.color.withValues(alpha: 0.35)),
            onPressed: () => context.push(item.route),
          );
        },
      ),
    );
  }
}

class _ShortcutItem {
  const _ShortcutItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String route;
  final Color color;
}
