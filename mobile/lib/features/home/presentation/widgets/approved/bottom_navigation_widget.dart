import 'package:flutter/material.dart';

import '../../../../../core/navigation/unread_badge_format.dart';
import '../../../../../core/motion/canlifal_motion_tokens.dart';
import '../../../../../core/motion/canlifal_motion_widgets.dart';
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
    this.onFortuneLongPress,
    this.inboxUnread = 0,
    required this.onProfile,
  });

  final HomeBottomTab activeTab;
  final VoidCallback onHome;
  final VoidCallback onSocial;
  final VoidCallback onCreate;
  final VoidCallback? onCreateLongPress;
  final VoidCallback onFortune;
  final VoidCallback? onFortuneLongPress;
  final int inboxUnread;
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
              label: 'Canlı',
              active: activeTab == HomeBottomTab.live,
              onTap: onCreate,
              onLongPress: onCreateLongPress,
            ),
            _NavItem(
              icon: Icons.auto_awesome_rounded,
              label: 'Mesaj/Fal',
              active: activeTab == HomeBottomTab.fortune,
              onTap: onFortune,
              onLongPress: onFortuneLongPress,
              badge: inboxUnread,
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
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkTheme;
    final activeColor = dark
        ? HomePremiumDesign.accent
        : context.colors.primary;
    final inactiveColor = dark
        ? HomeApprovedDesign.textMuted
        : context.colors.onSurfaceMuted;

    return CanlifalPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: CanlifalMotionTokens.micro,
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: active
            ? BoxDecoration(
                color: activeColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: activeColor.withValues(alpha: 0.28),
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CanlifalNavIcon(
                  icon: icon,
                  active: active,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
                if (badge > 0)
                  Positioned(
                    right: -4,
                    top: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: HomeApprovedDesign.liveRed,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        UnreadBadgeFormat.label(badge),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
