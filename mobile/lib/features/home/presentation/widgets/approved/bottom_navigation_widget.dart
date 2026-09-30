import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/motion/canlifal_motion_tokens.dart';
import '../../../../../core/motion/canlifal_motion_widgets.dart';
import '../../../../../core/theme/app_theme_extensions.dart';
import '../../../../../core/theme/canlifal_brand_colors.dart';

/// Alt navigasyon: Ana Sayfa · Sosyal · Sesli · (+ yayın/video) · Fal&Tarot · Tanış · Profil
class BottomNavigationWidget extends StatelessWidget {
  const BottomNavigationWidget({
    super.key,
    required this.activeTab,
    required this.onHome,
    required this.onSocial,
    required this.onVoice,
    required this.onCreate,
    required this.onFortuneTarot,
    required this.onMeet,
    required this.onProfile,
  });

  final HomeBottomTab activeTab;
  final VoidCallback onHome;
  final VoidCallback onSocial;
  final VoidCallback onVoice;
  final VoidCallback onCreate;
  final VoidCallback onFortuneTarot;
  final VoidCallback onMeet;
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
                compact: true,
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
                icon: Icons.headphones_rounded,
                activeIcon: Icons.headphones,
                label: 'Sesli',
                active: activeTab == HomeBottomTab.voice,
                onTap: onVoice,
              ),
              _CreateCameraItem(
                active: activeTab == HomeBottomTab.create,
                onTap: onCreate,
              ),
              _NavItem(
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                label: 'Fal&Tarot',
                compact: true,
                active: activeTab == HomeBottomTab.fortuneTarot,
                onTap: onFortuneTarot,
              ),
              _NavItem(
                icon: Icons.favorite_outline_rounded,
                activeIcon: Icons.favorite_rounded,
                label: 'Tanış',
                active: activeTab == HomeBottomTab.meet,
                onTap: onMeet,
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
  voice,
  create,
  fortuneTarot,
  meet,
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
    this.compact = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool compact;

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
        excludeSemantics: true,
        child: CanlifalPressable(
          onTap: handleTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: CanlifalMotionTokens.normal,
                curve: CanlifalMotionTokens.easeOut,
                width: active ? 44 : 34,
                height: 26,
                decoration: BoxDecoration(
                  color: active
                      ? activeColor.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
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
                  fontSize: compact ? 8.8 : 9.5,
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

/// Ortadaki animasyonlu kamera — canlı yayın + video yükle menüsü.
class _CreateCameraItem extends StatefulWidget {
  const _CreateCameraItem({
    required this.active,
    required this.onTap,
  });

  final bool active;
  final VoidCallback onTap;

  @override
  State<_CreateCameraItem> createState() => _CreateCameraItemState();
}

class _CreateCameraItemState extends State<_CreateCameraItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.of(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkTheme;
    void handleTap() {
      HapticFeedback.lightImpact();
      widget.onTap();
    }

    return Expanded(
      child: Semantics(
        button: true,
        selected: widget.active,
        label: 'Canlı yayın veya video yükle',
        onTap: handleTap,
        excludeSemantics: true,
        child: CanlifalPressable(
          scale: 0.92,
          onTap: handleTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final glow = 0.35 + _pulse.value * 0.25;
                  return Container(
                    width: 44,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: CanlifalBrandColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: dark ? 0.2 : 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CanlifalBrandColors.violet.withValues(alpha: glow),
                          blurRadius: 16 + _pulse.value * 6,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Yayın',
                maxLines: 1,
                textScaler: _navTextScaler(context),
                style: TextStyle(
                  fontSize: 8.8,
                  height: 1.05,
                  fontWeight: widget.active ? FontWeight.w800 : FontWeight.w600,
                  color: widget.active
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

TextScaler _navTextScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.1);
