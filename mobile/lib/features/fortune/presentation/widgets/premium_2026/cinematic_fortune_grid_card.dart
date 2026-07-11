import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../domain/entities/fortune_type_entity.dart';
import '../../data/fortune_type_images.dart';
import '../fortune_type_network_image.dart';

/// Sinematik fal grid kartı — glassmorphism, neon glow, tap scale (emoji yok).
class CinematicFortuneGridCard extends StatefulWidget {
  const CinematicFortuneGridCard({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.radius = 30,
  });

  final FortuneTypeEntity type;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double radius;

  @override
  State<CinematicFortuneGridCard> createState() => _CinematicFortuneGridCardState();
}

class _CinematicFortuneGridCardState extends State<CinematicFortuneGridCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final glow = FortuneTypeImages.glowColor(widget.type.slug);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: RepaintBoundary(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: _pressed ? 0.55 : 0.28),
                  blurRadius: _pressed ? 28 : 16,
                  spreadRadius: _pressed ? 2 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FortuneTypeNetworkImage(
                    slug: widget.type.slug,
                    accent: widget.type.accent,
                    borderRadius: 0,
                    imageWidth: 1000,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                        stops: const [0.35, 0.65, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 0.6,
                            color: Colors.white,
                            shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 11,
                            height: 1.3,
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
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.08, end: 0);
  }
}
