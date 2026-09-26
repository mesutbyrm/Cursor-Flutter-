import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/motion/canlifal_motion_tokens.dart';
import '../../../../../core/motion/canlifal_motion_widgets.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/theme/canlifal_brand_colors.dart';

/// Uygulama alt navigasyonu — antrasit zemin, hap göstergesi, ortada
/// öne çıkan "Canlı" oluşturma butonu.
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
    required this.onProfile,
  });

  final HomeBottomTab activeTab;
  final VoidCallback onHome;
  final VoidCallback onSocial;
  final VoidCallback onCreate;
  final VoidCallback? onCreateLongPress;
  final VoidCallback onFortune;
  final VoidCallback? onFortuneLongPress;
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
              _CreateItem(
                active: activeTab == HomeBottomTab.live,
                onTap: onCreate,
                onLongPress: onCreateLongPress,
              ),
              _NavItem(
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                label: 'Fal & Tarot',
                active: activeTab == HomeBottomTab.fortune,
                onTap: onFortune,
                onLongPress: onFortuneLongPress,
                // Bildirim/mesaj rozeti buraya gelmez; hepsi Gelen Kutusu'nda.
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

enum HomeBottomTab { home, social, live, fortune, profile }

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
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

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
                width: active ? 52 : 40,
                height: 30,
                decoration: BoxDecoration(
                  color: active
                      ? activeColor.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: CanlifalNavIcon(
                  icon: active ? activeIcon : icon,
                  active: active,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: CanlifalMotionTokens.micro,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  fontSize: 10.5,
                  height: 1.1,
                  letterSpacing: 0.1,
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

/// Ortadaki oluşturma butonu — yayın/oda/gönderi açma sayfasını açar.
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
        label: 'Canlı — yayın veya oda başlat',
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
                width: 46,
                height: 32,
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
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Canlı',
                maxLines: 1,
                textScaler: _navTextScaler(context),
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.1,
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
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15);
