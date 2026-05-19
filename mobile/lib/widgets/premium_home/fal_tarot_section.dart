import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/premium_tarot_offer.dart';
import '../../theme/premium_live_theme.dart';

class FalTarotSection extends StatelessWidget {
  const FalTarotSection({super.key, required this.offers});

  final List<PremiumTarotOffer> offers;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        physics: const BouncingScrollPhysics(),
        itemCount: offers.length,
        separatorBuilder: (_, __) => SizedBox(width: 3.w),
        itemBuilder: (context, i) {
          final o = offers[i];
          return _TarotCard(offer: o, index: i)
              .animate()
              .fadeIn(delay: (100 * i).ms, duration: 500.ms)
              .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
        },
      ),
    );
  }
}

class _TarotCard extends StatelessWidget {
  const _TarotCard({required this.offer, required this.index});

  final PremiumTarotOffer offer;
  final int index;

  @override
  Widget build(BuildContext context) {
    final w = 38.w.clamp(132.0, 168.0);
    return Container(
      width: w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: PremiumLiveTheme.neonGold.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            gradient: offer.borderGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(1.6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(decoration: BoxDecoration(gradient: offer.cardGradient)),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TarotParticlePainter(seed: index * 17 + 3),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(3.w, 2.2.h, 3.w, 2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.2.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: PremiumLiveTheme.neonGold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          offer.icon,
                          color: PremiumLiveTheme.neonGold,
                          size: 22.sp,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        offer.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        offer.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 10.5.sp,
                          height: 1.25,
                          color: PremiumLiveTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 4.seconds,
          color: Colors.white.withValues(alpha: 0.035),
        );
  }
}

class _TarotParticlePainter extends CustomPainter {
  _TarotParticlePainter({required this.seed});

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final p = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 18; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 1.4 + 0.3;
      p.color = Colors.white.withValues(alpha: rnd.nextDouble() * 0.12 + 0.02);
      canvas.drawCircle(Offset(x, y), r, p);
    }
  }

  @override
  bool shouldRepaint(covariant _TarotParticlePainter oldDelegate) =>
      oldDelegate.seed != seed;
}
