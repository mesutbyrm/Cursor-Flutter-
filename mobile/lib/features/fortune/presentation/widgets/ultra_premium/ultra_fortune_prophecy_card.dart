import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/motion/canlifal_tarot_flip_card.dart';
import '../../data/fortune_catalog.dart';
import '../../data/fortune_type_images.dart';
import '../fortune_type_cover_image.dart';
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

class _CinematicTarotThumb extends StatefulWidget {
  const _CinematicTarotThumb();

  @override
  State<_CinematicTarotThumb> createState() => _CinematicTarotThumbState();
}

class _CinematicTarotThumbState extends State<_CinematicTarotThumb> {
  var _revealed = false;

  @override
  Widget build(BuildContext context) {
    final glow = FortuneTypeImages.glowColor('gunluk-fal');

    Widget cardFace(Widget child) {
      return Container(
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
          child: child,
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _revealed = !_revealed),
      child: CanlifalTarotFlipCard(
        width: 64,
        height: 88,
        flipped: _revealed,
        front: cardFace(
          Stack(
            fit: StackFit.expand,
            children: [
              FortuneTypeCoverImage(
                slug: 'gunluk-fal',
                accent: glow,
                imageWidth: 400,
                showOverlay: true,
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: Icon(
                  Icons.style_rounded,
                  color: Colors.white.withValues(alpha: 0.75),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
        back: cardFace(
          ColoredBox(
            color: const Color(0xFF1A0F2E),
            child: Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.95),
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
