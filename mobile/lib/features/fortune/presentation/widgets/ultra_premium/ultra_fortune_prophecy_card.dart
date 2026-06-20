import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/fortune_catalog.dart';
import '../../data/fortune_type_images.dart';
import '../premium_ai/fortune_image_shimmer.dart';
import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_ripple_button.dart';
import 'ultra_fortune_tokens.dart';

/// BUGÜNÜN KEHANETİ — sinematik tarot vitrin + Liquid Glass panel.
class UltraFortuneProphecyCard extends StatelessWidget {
  const UltraFortuneProphecyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: UltraFortuneLiquidSurface(
        elevated: true,
        goldAccent: true,
        borderRadius: BorderRadius.circular(UltraFortuneTokens.cardRadius),
        padding: const EdgeInsets.all(16),
        blur: 44,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _CinematicTarotThumb(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BUGÜNÜN KEHANETİ',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: UltraFortuneTokens.metallicGold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Evren seninle konuşuyor.\n'
                    'İç sesine kulak ver.\n'
                    'Bugün alacağın karar geleceğini güzelleştirecek.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            UltraFortuneRippleButton(
              compact: true,
              label: 'KEHANETİ OKU',
              onPressed: () => context.push(
                '/fortune/${FortuneCatalog.dailyFortune.slug}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CinematicTarotThumb extends StatelessWidget {
  const _CinematicTarotThumb();

  @override
  Widget build(BuildContext context) {
    final url = FortuneTypeImages.urlFor('tarot', width: 400);
    final glow = FortuneTypeImages.glowColor('tarot');

    return Container(
      width: 64,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 1,
          ),
          ...UltraFortuneTokens.goldGlow(),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 300,
              placeholder: (_, _) =>
                  const FortuneImageShimmer(accent: Color(0xFFB832FF)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.9),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
