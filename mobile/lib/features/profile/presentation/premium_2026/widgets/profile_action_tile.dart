import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../profile_theme.dart';

/// Premium hızlı işlem / panel kartı — 3 sütun grid veya yatay şerit.
class ProfileActionTile extends StatelessWidget {
  const ProfileActionTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.gradient,
    this.iconColor,
    this.badge,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Koyu temadaki dolgu; açık temada ilk rengin tonu kullanılır.
  final List<Color>? gradient;
  final Color? iconColor;
  final int? badge;

  /// Yatay şerit (sabit yükseklik) için daha sıkı ölçüler.
  final bool compact;

  /// [compact] kutucuğun ihtiyaç duyduğu yükseklik (2 satır etiket + %130 yazı).
  static const double compactHeight = 92;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkTheme;
    final colors = gradient ??
        [
          ProfilePremiumTheme.neonPurple.withValues(alpha: 0.35),
          ProfilePremiumTheme.deepBg.withValues(alpha: 0.9),
        ];
    final accent = colors.first.withValues(alpha: 1);
    final radius = BorderRadius.circular(
      compact ? 16 : ProfilePremiumTheme.radiusSm,
    );

    final decoration = dark
        ? BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(color: ProfilePremiumTheme.glassBorder),
          )
        : BoxDecoration(
            borderRadius: radius,
            color: Color.alphaBlend(
              accent.withValues(alpha: 0.10),
              context.colors.surface,
            ),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          );

    final iconSize = compact ? 24.0 : 28.0;
    final fg = dark ? Colors.white : context.colors.onSurface;

    return Semantics(
      button: true,
      label: badge != null && badge! > 0 ? '$label, $badge yeni' : label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: decoration,
            child: Padding(
              padding: compact
                  ? const EdgeInsets.symmetric(horizontal: 6, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        icon,
                        size: iconSize,
                        color: iconColor ??
                            (dark
                                ? Colors.white.withValues(alpha: 0.95)
                                : ProfilePremiumTheme.accentOf(context)),
                      ),
                      if (badge != null && badge! > 0)
                        Positioned(
                          right: -10,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.liveRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badge! > 99 ? '99+' : '$badge',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? 6 : 10),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textScaler: compact
                        ? MediaQuery.textScalerOf(
                            context,
                          ).clamp(maxScaleFactor: 1.3)
                        : null,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 11 : 12,
                      height: 1.15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
