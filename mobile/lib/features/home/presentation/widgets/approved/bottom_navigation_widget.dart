import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme_extensions.dart';
import '../../theme/home_approved_design.dart';
import '../../theme/home_premium_design.dart';

/// Ana sayfa alt navigasyon — premium koyu cam görünüm.
class BottomNavigationWidget extends StatelessWidget {
  const BottomNavigationWidget({
    super.key,
    required this.activeTab,
    required this.onHome,
    required this.onSocial,
    required this.onCreate,
    this.onCreateLongPress,
    required this.onFortune,
    required this.onProfile,
  });

  final HomeBottomTab activeTab;
  final VoidCallback onHome;
  final VoidCallback onSocial;
  final VoidCallback onCreate;
  final VoidCallback? onCreateLongPress;
  final VoidCallback onFortune;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final dark = context.isDarkTheme;
    final bg = dark
        ? HomeApprovedDesign.background.withValues(alpha: 0.96)
        : context.colors.surface;
    final borderColor = dark
        ? HomeApprovedDesign.border.withValues(alpha: 0.85)
        : context.colors.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: dark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 8, 8, bottom + 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Ana Sayfa',
              active: activeTab == HomeBottomTab.home,
              onTap: onHome,
            ),
            _NavItem(
              icon: Icons.groups_rounded,
              label: 'Sosyal',
              active: activeTab == HomeBottomTab.social,
              onTap: onSocial,
            ),
            _NavItem(
              icon: Icons.mic_rounded,
              label: 'Yayın',
              active: activeTab == HomeBottomTab.live,
              onTap: onCreate,
              onLongPress: onCreateLongPress,
            ),
            _NavItem(
              icon: Icons.auto_awesome_rounded,
              label: 'Fal & Tarot',
              active: activeTab == HomeBottomTab.fortune,
              onTap: onFortune,
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profil',
              active: activeTab == HomeBottomTab.profile,
              onTap: onProfile,
            ),
          ],
        ),
      ),
    );
  }
}

enum HomeBottomTab { home, social, live, fortune, profile }

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkTheme;
    final activeColor = dark
        ? HomePremiumDesign.accent
        : context.colors.primary;
    final inactiveColor = dark
        ? HomeApprovedDesign.textMuted
        : context.colors.onSurfaceMuted;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: active
            ? BoxDecoration(
                color: activeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: active ? activeColor : inactiveColor),
            if (active) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: activeColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
