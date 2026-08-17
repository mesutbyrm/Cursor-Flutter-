import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

/// Sosyal sekme keşif kısayolları — ünlüler, fan kulüp, canlı ve sesli odalar.
class SocialDiscoverShortcuts extends StatelessWidget {
  const SocialDiscoverShortcuts({super.key});

  static const _items = [
    _ShortcutItem(
      icon: Icons.star_rounded,
      label: 'Ünlüler',
      route: '/celebrities-hub',
      color: AppThemeColors.coinGold,
    ),
    _ShortcutItem(
      icon: Icons.favorite_rounded,
      label: 'Fan Club',
      route: '/fan-club-hub',
      color: AppThemeColors.accentPink,
    ),
    _ShortcutItem(
      icon: Icons.live_tv_rounded,
      label: 'Canlı',
      route: '/live',
      color: AppThemeColors.liveRed,
    ),
    _ShortcutItem(
      icon: Icons.mic_rounded,
      label: 'Sesli',
      route: '/voice-rooms',
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
