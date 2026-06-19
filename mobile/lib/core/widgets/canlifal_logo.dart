import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:google_fonts/google_fonts.dart';


/// CanlıFal marka logosu — yıldız + gradyan wordmark (raster ikon gerekmez).
class CanlifalLogo extends StatelessWidget {
  const CanlifalLogo({
    super.key,
    this.size = 88,
    this.showWordmark = true,
    this.animateGlow = false,
  });

  final double size;
  final bool showWordmark;
  final bool animateGlow;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: context.colors.brandGradient,
        boxShadow: AppThemeColors.glowShadow(AppThemeColors.accentPink, blur: size * 0.35),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: size * 0.42,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          Positioned(
            bottom: size * 0.18,
            child: Text(
              'CF',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: size * 0.18,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );

    if (!showWordmark) return icon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(height: size * 0.28),
        ShaderMask(
          shaderCallback: (b) => context.colors.brandGradient.createShader(b),
          child: Text(
            'CanlıFal',
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Yatay şekilli marka yazısı — ikon yok; ana sayfa ve üst barlar için.
class CanlifalWordmark extends StatelessWidget {
  const CanlifalWordmark({
    super.key,
    this.fontSize = 26,
    this.compact = false,
  });

  final double fontSize;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      height: 1,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
            blurRadius: compact ? 10 : 16,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: AppThemeColors.accentPink.withValues(alpha: 0.22),
            blurRadius: compact ? 14 : 22,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'Canlı',
            style: base.copyWith(
              color: Colors.white.withValues(alpha: 0.96),
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFF4FD8),
                Color(0xFFB832FF),
                Color(0xFFE9D5FF),
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ).createShader(bounds),
            child: Text(
              'Fal',
              style: GoogleFonts.playfairDisplay(
                fontSize: fontSize * 1.08,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.3,
                height: 1,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
