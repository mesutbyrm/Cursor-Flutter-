import 'package:flutter/material.dart';

import '../../theme/home_approved_design.dart';

/// Onaylı mockup — Ana Sayfa, Sosyal, Yayın/Medya, Jeton, Profil.
class BottomNavigationWidget extends StatelessWidget {
  const BottomNavigationWidget({
    super.key,
    required this.activeTab,
    required this.onHome,
    required this.onSocial,
    required this.onCreate,
    required this.onJeton,
    required this.onProfile,
  });

  final HomeBottomTab activeTab;
  final VoidCallback onHome;
  final VoidCallback onSocial;
  final VoidCallback onCreate;
  final VoidCallback onJeton;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: HomeApprovedDesign.background,
        border: Border(
          top: BorderSide(color: HomeApprovedDesign.border),
        ),
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
            active: false,
            onTap: onCreate,
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

enum HomeBottomTab { home, social, jeton, profile }

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? HomeApprovedDesign.purple : HomeApprovedDesign.textMuted;

    return GestureDetector(
      onTap: onTap,
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
