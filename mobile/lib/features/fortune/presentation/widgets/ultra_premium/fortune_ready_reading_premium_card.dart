import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/fortune_type_images.dart';
import '../fortune_type_cover_image.dart';
import 'ultra_fortune_cover_backdrop.dart';
import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_tokens.dart';

/// Hazır yorum listesi — sinematik kapak + liquid glass panel.
class FortuneReadyReadingPremiumCard extends StatefulWidget {
  const FortuneReadyReadingPremiumCard({
    super.key,
    required this.slug,
    required this.title,
    required this.body,
    required this.accent,
    required this.onTap,
  });

  final String slug;
  final String title;
  final String body;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<FortuneReadyReadingPremiumCard> createState() =>
      _FortuneReadyReadingPremiumCardState();
}

class _FortuneReadyReadingPremiumCardState
    extends State<FortuneReadyReadingPremiumCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final glow = FortuneTypeImages.glowColor(widget.slug);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: UltraFortuneLiquidSurface(
          elevated: true,
          goldAccent: true,
          borderRadius: BorderRadius.circular(22),
          padding: EdgeInsets.zero,
          blur: 44,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                UltraFortuneCoverBackdrop(
                  slug: widget.slug,
                  accent: widget.accent,
                  opacity: 0.32,
                  imageWidth: 720,
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _CoverThumb(slug: widget.slug, accent: glow),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.9),
                      ),
                    ],
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

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({required this.slug, required this.accent});

  final String slug;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: FortuneTypeCoverImage(
          slug: slug,
          accent: accent,
          imageWidth: 400,
          showOverlay: true,
        ),
      ),
    );
  }
}
