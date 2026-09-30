import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/motion/canlifal_motion_tokens.dart';
import '../../../../../core/motion/canlifal_motion_widgets.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/theme/canlifal_brand_colors.dart';

/// Uygulama alt navigasyonu — ana sayfa, sosyal, canlı, ortada video yükleme,
/// fal, tarot ve profil.
class BottomNavigationWidget extends StatelessWidget {
  const BottomNavigationWidget({
    super.key,
    required this.activeTab,
    required this.onHome,
    required this.onSocial,
    required this.onLive,
    required this.onCreate,
    required this.onFortune,
    required this.onTarot,
    required this.onProfile,
  });

  final HomeBottomTab activeTab;
  final VoidCallback onHome;
  final VoidCallback onSocial;
  final VoidCallback onLive;
  final VoidCallback onCreate;
  final VoidCallback onFortune;
  final VoidCallback onTarot;
  final VoidCallback onProfile;

  static const double barHeight = 62;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final dark = context.isDarkTheme;
    final colors = context.colors;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.tokens.navBarBackground,
        border: Border(
          top: BorderSide(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : colors.outlineVariant,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.45 : 0.04),
            blurRadius: dark ? 20 : 12,
            offset: Offset(0, dark ? -6 : -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Ana Sayfa',
                shortLabel: true,
                active: activeTab == HomeBottomTab.home,
                onTap: onHome,
              ),
              _NavItem(
                icon: Icons.groups_outlined,
                activeIcon: Icons.groups_rounded,
                label: 'Sosyal',
                active: activeTab == HomeBottomTab.social,
                onTap: onSocial,
              ),
              _NavItem(
                icon: Icons.podcasts_outlined,
                activeIcon: Icons.podcasts_rounded,
                label: 'Canlı',
                active: activeTab == HomeBottomTab.live,
                onTap: onLive,
              ),
              _CreateItem(
                active: activeTab == HomeBottomTab.create,
                onTap: onCreate,
              ),
              _NavItem(
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                label: 'Fal',
                active: activeTab == HomeBottomTab.fortune,
                onTap: onFortune,
              ),
              _NavItem(
                icon: Icons.style_outlined,
                activeIcon: Icons.style_rounded,
                label: 'Tarot',
                active: activeTab == HomeBottomTab.tarot,
                onTap: onTarot,
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
                active: activeTab == HomeBottomTab.profile,
                onTap: onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum HomeBottomTab {
  home,
  social,
  live,
  create,
  fortune,
  tarot,
  profile,
}

Color _activeColor(BuildContext context) => context.isDarkTheme
    ? CanlifalBrandColors.violetBright
    : context.colors.primary;

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.onLongPress,
    this.shortLabel = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool shortLabel;

  @override
  Widget build(BuildContext context) {
    final activeColor = _activeColor(context);
    final inactiveColor = context.colors.onSurfaceMuted;

    void handleTap() {
      HapticFeedback.selectionClick();
      onTap();
    }

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        onTap: handleTap,
        onLongPress: onLongPress,
        excludeSemantics: true,
        child: CanlifalPressable(
          onTap: handleTap,
          onLongPress: onLongPress,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: CanlifalMotionTokens.normal,
                curve: CanlifalMotionTokens.easeOut,
                width: active ? 48 : 36,
                height: 28,
                decoration: BoxDecoration(
                  color: active
                      ? activeColor.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: CanlifalNavIcon(
                  icon: active ? activeIcon : icon,
                  active: active,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: CanlifalMotionTokens.micro,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontSize: shortLabel ? 9.5 : 10,
                  height: 1.05,
                  letterSpacing: 0,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? context.colors.onSurface : inactiveColor,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: _navTextScaler(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ortadaki video yükleme butonu.
class _CreateItem extends StatelessWidget {
  const _CreateItem({
    required this.active,
    required this.onTap,
    this.onLongPress,
  });

  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkTheme;
    void handleTap() {
      HapticFeedback.lightImpact();
      onTap();
    }

    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: 'Video yükle',
        onTap: handleTap,
        onLongPress: onLongPress,
        excludeSemantics: true,
        child: CanlifalPressable(
          scale: 0.92,
          onTap: handleTap,
          onLongPress: onLongPress,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 30,
                decoration: BoxDecoration(
                  gradient: CanlifalBrandColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: dark ? 0.14 : 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CanlifalBrandColors.violet.withValues(
                        alpha: dark ? 0.45 : 0.3,
                      ),
                      blurRadius: 14,
                      spreadRadius: -4,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Yükle',
                maxLines: 1,
                textScaler: _navTextScaler(context),
                style: TextStyle(
                  fontSize: 9.5,
                  height: 1.05,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active
                      ? context.colors.onSurface
                      : context.colors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sabit yükseklikli barda taşmayı önlerken büyük yazı tercihini kısmen korur.
TextScaler _navTextScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.12);
