import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:canlifal_social/core/ui/premium/premium_skeleton.dart';
import '../../../../home/presentation/theme/home_approved_design.dart';
import '../../../../home/presentation/theme/home_premium_design.dart';
import '../fortune_type_cover_image.dart';

/// Fal kart iskeleti — görsel + başlık alanı.
class FortunePremiumCardSkeleton extends StatelessWidget {
  const FortunePremiumCardSkeleton({
    super.key,
    this.width = FortunePremiumCard.cardWidth,
    this.height = FortunePremiumCard.cardHeight,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return PremiumSkeleton(
      width: width,
      height: height,
      borderRadius: BorderRadius.all(
        Radius.circular(FortunePremiumCard.radius),
      ),
    );
  }
}

/// Fal & Tarot V2 — premium yatay/grid kart.
class FortunePremiumCard extends StatefulWidget {
  const FortunePremiumCard({
    super.key,
    required this.slug,
    required this.title,
    required this.accent,
    required this.onTap,
    this.subtitle,
    this.imageUrl,
    this.jetonCost,
    this.emoji,
    this.width = cardWidth,
    this.height = cardHeight,
    this.compact = false,
  });

  static const cardWidth = 160.0;
  static const cardHeight = 220.0;
  static const radius = 20.0;

  static double cardWidthFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= 360) return 148;
    if (w <= 390) return 156;
    return cardWidth;
  }

  final String slug;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final int? jetonCost;
  final Color accent;
  final String? emoji;
  final VoidCallback onTap;
  final double width;
  final double height;
  final bool compact;

  @override
  State<FortunePremiumCard> createState() => _FortunePremiumCardState();
}

class _FortunePremiumCardState extends State<FortunePremiumCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final showPrice = widget.jetonCost != null && widget.jetonCost! > 0;
    final titleLine = _titleWithEmoji();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FortunePremiumCard.radius),
              border: Border.all(
                color: HomePremiumDesign.accent.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FortunePremiumCard.radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FortuneTypeCoverImage(
                    slug: widget.slug,
                    accent: widget.accent,
                    imageWidth: 720,
                    networkUrlOverride: widget.imageUrl,
                    showOverlay: false,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.08),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.52),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                        stops: const [0.0, 0.42, 0.72, 1.0],
                      ),
                    ),
                  ),
                  if (showPrice)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _PriceBadge(jetonCost: widget.jetonCost!),
                    ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: widget.compact ? 10 : 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          titleLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: widget.compact ? 13 : 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                        if (!widget.compact &&
                            widget.subtitle != null &&
                            widget.subtitle!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ],
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

  String _titleWithEmoji() {
    final emoji = widget.emoji?.trim();
    if (emoji != null && emoji.isNotEmpty && !emoji.startsWith('http')) {
      return '$emoji ${widget.title}';
    }
    return widget.title;
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.jetonCost});

  final int jetonCost;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HomeApprovedDesign.gold.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '$jetonCost Jeton',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: HomeApprovedDesign.gold,
          ),
        ),
      ),
    );
  }
}
