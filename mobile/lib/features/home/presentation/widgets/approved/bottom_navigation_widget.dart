import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../theme/home_approved_design.dart';

/// Onaylı mockup — Ana Sayfa, Sosyal, Yayın/Medya, Jeton, Profil.
class BottomNavigationWidget extends StatelessWidget {
  const BottomNavigationWidget({
    super.key,
    required this.activeTab,
    required this.onHome,
    required this.onSocial,
    required this.onCreate,
    this.onCreateLongPress,
    required this.onJeton,
    required this.onProfile,
  });

  final HomeBottomTab activeTab;
  final VoidCallback onHome;
  final VoidCallback onSocial;
  final VoidCallback onCreate;
  final VoidCallback? onCreateLongPress;
  final VoidCallback onJeton;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final dark = context.isDarkTheme;
    final bg = dark
        ? HomeApprovedDesign.background
        : context.colors.surface;
    final borderColor = dark
        ? HomeApprovedDesign.border
        : context.colors.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
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
            icon: Icons.diamond_rounded,
            label: 'Jeton',
            active: activeTab == HomeBottomTab.jeton,
            onTap: onJeton,
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profil',
            active: activeTab == HomeBottomTab.profile,
            onTap: onProfile,
          ),
        ],
      ),
    );
  }
}

enum HomeBottomTab { home, social, live, jeton, profile }

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
    final color = active
        ? (dark ? HomeApprovedDesign.purple : context.colors.primary)
        : (dark
            ? HomeApprovedDesign.textMuted
            : context.colors.onSurfaceMuted);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            if (active) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
