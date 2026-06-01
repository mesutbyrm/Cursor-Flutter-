import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../data/fortune_catalog.dart';
import 'fortune_hub_crystal_illustration.dart';

/// Fal & Tarot hero — kozmik kart, metin, FALINI AÇ, kristal küre.
class FortuneHubHeroBanner extends StatelessWidget {
  const FortuneHubHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Container(
        height: 188,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.accentPurple.withValues(alpha: 0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPurple.withValues(alpha: 0.25),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2A1548),
                      Color(0xFF12081F),
                      Color(0xFF0A0118),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -30,
                top: -20,
                child: Icon(
                  Icons.blur_on_rounded,
                  size: 160,
                  color: AppColors.accentPurple.withValues(alpha: 0.22),
                ),
              ),
              const Positioned(left: 20, top: 28, child: _StarDot(size: 2)),
              const Positioned(left: 52, top: 14, child: _StarDot(size: 1.5)),
              const Positioned(right: 100, top: 22, child: _StarDot(size: 2)),
              const Positioned(right: 48, top: 40, child: _StarDot(size: 1.2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 8, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                height: 1.28,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                              children: [
                                TextSpan(text: 'Kendini keşfet, geleceğini '),
                                TextSpan(
                                  text: 'aydınlat',
                                  style: TextStyle(
                                    color: Color(0xFFC084FC),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fal ve tarotun mistik dünyasına hoş geldin.',
                            style: TextStyle(
                              color: AppColors.textSecondary.withValues(alpha: 0.92),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _FaliniAcButton(
                            onPressed: () => context.push(
                              '/fortune/${FortuneCatalog.dailyFortune.slug}',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const FortuneHubCrystalIllustration(height: 128),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _StarDot extends StatelessWidget {
  const _StarDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _FaliniAcButton extends StatelessWidget {
  const _FaliniAcButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF9333EA), Color(0xFF5B21B6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'FALINI AÇ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
