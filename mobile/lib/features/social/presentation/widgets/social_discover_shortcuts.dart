import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../utils/social_discover_shortcut_labels.dart';

/// Sosyal üst sekmeleri — Tümü · Takip · Falcılar · Ünlüler · Fan Club.
class SocialDiscoverShortcuts extends StatelessWidget {
  const SocialDiscoverShortcuts({super.key});

  static const _icons = <(IconData, Color)>[
    (Icons.home_rounded, Colors.white),
    (Icons.people_outline_rounded, Color(0xFFB9A7FF)),
    (Icons.star_rounded, Color(0xFFFFC928)),
    (Icons.workspace_premium_rounded, Color(0xFFFFC928)),
    (Icons.favorite_rounded, Color(0xFFFF2D55)),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.04)
              : context.colors.surfaceElevated,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : context.colors.outlineVariant,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              for (var i = 0; i < socialDiscoverShortcutLabels.length; i++)
                _TabPill(
                  icon: _icons[i].$1,
                  iconColor: _icons[i].$2,
                  label: socialDiscoverShortcutLabels[i],
                  selected: socialDiscoverShortcutRoutes[i].isEmpty,
                  onTap: socialDiscoverShortcutRoutes[i].isEmpty
                      ? null
                      : () => context.push(socialDiscoverShortcutRoutes[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9D4DFF)],
                  ),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? Colors.white : iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? Colors.white : context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
