import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:canlifal_social/core/ui/premium/premium_skeleton.dart';
import '../../../fortune/presentation/widgets/fortune_type_cover_image.dart';
import '../../../home/presentation/theme/home_approved_design.dart';
import '../../../home/presentation/theme/home_premium_design.dart';
import '../../domain/entities/bana_ozel_entities.dart';
import '../data/bana_ozel_display_resolver.dart';

/// Bana Özel kart iskeleti.
class BanaOzelPremiumCardSkeleton extends StatelessWidget {
  const BanaOzelPremiumCardSkeleton({
    super.key,
    this.width = BanaOzelPremiumCard.cardWidth,
    this.height = BanaOzelPremiumCard.cardHeight,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return PremiumSkeleton(
      width: width,
      height: height,
      borderRadius: BorderRadius.all(
        Radius.circular(BanaOzelPremiumCard.radius),
      ),
    );
  }
}

/// Bana Özel V2 — premium yatay vitrin kartı.
class BanaOzelPremiumCard extends StatefulWidget {
  const BanaOzelPremiumCard({
    super.key,
    required this.item,
    required this.onTap,
    this.affordable = true,
    this.width = cardWidth,
    this.height = cardHeight,
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

  final BanaOzelItemEntity item;
  final VoidCallback onTap;
  final bool affordable;
  final double width;
  final double height;

  @override
  State<BanaOzelPremiumCard> createState() => _BanaOzelPremiumCardState();
}

class _BanaOzelPremiumCardState extends State<BanaOzelPremiumCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final coverSlug = BanaOzelDisplayResolver.coverSlugFor(widget.item);
    final accent = BanaOzelDisplayResolver.accentFor(widget.item);
    final imageUrl = BanaOzelDisplayResolver.imageUrlFor(widget.item);
    final subtitle = BanaOzelDisplayResolver.subtitleFor(widget.item);
    final title = BanaOzelDisplayResolver.titleWithIcon(widget.item);
    final showPrice = widget.item.jetonCost > 0;

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
              borderRadius: BorderRadius.circular(BanaOzelPremiumCard.radius),
              border: Border.all(
                color: HomePremiumDesign.accent.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BanaOzelPremiumCard.radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FortuneTypeCoverImage(
                    slug: coverSlug,
                    accent: accent,
                    imageWidth: 720,
                    networkUrlOverride: imageUrl,
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
                          Colors.black.withValues(alpha: 0.84),
                        ],
                        stops: const [0.0, 0.42, 0.72, 1.0],
                      ),
                    ),
                  ),
                  if (showPrice)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _PriceBadge(
                        jetonCost: widget.item.jetonCost,
                        affordable: widget.affordable,
                      ),
                    ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.15,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
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
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({
    required this.jetonCost,
    required this.affordable,
  });

  final int jetonCost;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (affordable ? HomeApprovedDesign.gold : HomeApprovedDesign.textSecondary)
              .withValues(alpha: 0.45),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '$jetonCost Jeton',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: affordable
                ? HomeApprovedDesign.gold
                : HomeApprovedDesign.textSecondary,
          ),
        ),
      ),
    );
  }
}
