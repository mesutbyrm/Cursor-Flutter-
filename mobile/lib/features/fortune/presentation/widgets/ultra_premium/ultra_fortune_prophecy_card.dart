import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/fortune_catalog.dart';
import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_ripple_button.dart';
import 'ultra_fortune_tokens.dart';

/// BUGÜNÜN KEHANETİ — tam genişlik Liquid Glass panel.
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
            _TarotIllustration(),
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

class _TarotIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3D1A6E),
            Color(0xFF1A0A32),
          ],
        ),
        border: Border.all(
          color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: UltraFortuneTokens.goldGlow(),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text('☀️', style: TextStyle(fontSize: 22)),
          Positioned(
            bottom: 8,
            child: Container(
              width: 10,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF3C4), Color(0xFFFFB347)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB347).withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            child: Container(
              width: 6,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                color: const Color(0xFFFF6B35).withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
