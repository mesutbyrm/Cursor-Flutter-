import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/fortune_catalog.dart';
import 'ultra_fortune_crystal_ball.dart';
import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_ripple_button.dart';
import 'ultra_fortune_tokens.dart';

/// Hero — responsive kristal küre, taşma yok, SafeArea uyumlu.
class UltraFortuneHeroSection extends StatelessWidget {
  const UltraFortuneHeroSection({super.key});

  static double _ballSize(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    // Küçük ekranlarda küreyi küçült; üst bölümün ~%28'ini geçmesin.
    final byWidth = w * 0.34;
    final byHeight = h * 0.22;
    return byWidth.clamp(120.0, 200.0).clamp(0, byHeight);
  }

  @override
  Widget build(BuildContext context) {
    final ballSize = _ballSize(context);
    final ballBoxHeight = ballSize * 1.02;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _HeroCopy(
                  onCta: () => context.push(
                    '/fortune/${FortuneCatalog.dailyFortune.slug}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: ballSize,
                height: ballBoxHeight,
                child: ClipRect(
                  child: RepaintBoundary(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: UltraFortuneCrystalBall(size: ballSize),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(
                child: _SideInfoCard(
                  label: 'Enerjin',
                  value: 'Yüksek',
                  icon: Icons.diamond_rounded,
                  iconColor: UltraFortuneTokens.softLilac,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _SideInfoCard(
                  label: 'Ay Evresi',
                  value: 'Şişkin Ay',
                  icon: Icons.nightlight_round,
                  iconColor: UltraFortuneTokens.metallicGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SocialProofStrip(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onCta});

  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.playfairDisplay(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      height: 1.22,
      color: Colors.white,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.white.withValues(alpha: 0.95),
              UltraFortuneTokens.metallicGold.withValues(alpha: 0.9),
            ],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(bounds),
          child: Text(
            'Kaderin\nBugün Sana\nNe Söylüyor?',
            style: titleStyle,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tarot, Kahve ve Astroloji ile\ngeleceğini keşfet.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        UltraFortuneRippleButton(
          label: 'FALINA BAK',
          onPressed: onCta,
        ),
      ],
    );
  }
}

class _SideInfoCard extends StatelessWidget {
  const _SideInfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return UltraFortuneLiquidSurface(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: BorderRadius.circular(18),
      blur: 40,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.18),
              boxShadow: UltraFortuneTokens.purpleGlow(blur: 10),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.85),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialProofStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return UltraFortuneLiquidSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: BorderRadius.circular(20),
      blur: 36,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 28,
            child: Stack(
              children: List.generate(4, (i) {
                return Positioned(
                  left: i * 18.0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: [
                      UltraFortuneTokens.electricPurple,
                      const Color(0xFF6366F1),
                      UltraFortuneTokens.softLilac,
                      UltraFortuneTokens.metallicGold,
                    ][i].withValues(alpha: 0.85),
                    child: Icon(
                      [
                        Icons.nightlight_round,
                        Icons.auto_awesome_rounded,
                        Icons.blur_on_rounded,
                        Icons.star_rounded,
                      ][i],
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '23.8K kişi bugün falına baktı',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
