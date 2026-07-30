import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../feed/presentation/widgets/discover_premium_2026/discover_premium_visual.dart';

/// 2026 premium ana sayfa cam kartı — Keşfet / Gold satırları.
class PremiumHomeGlassCard extends StatelessWidget {
  const PremiumHomeGlassCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.subtitle,
    this.heroTag,
    this.width = 148,
    this.height = 200,
    this.accentColor = DiscoverPremiumVisual.primary,
    this.onTap,
    this.shimmer = false,
  });

  final String title;
  final String? subtitle;
  final String imageUrl;
  final String? heroTag;
  final double width;
  final double height;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool shimmer;

  static const radius = DiscoverPremiumVisual.cardRadius;

  @override
  Widget build(BuildContext context) {
    final card = RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _BackgroundImage(url: imageUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const SizedBox.expand(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.72),
                    width: 1.2,
                  ),
                  boxShadow: DiscoverPremiumVisual.cardGlow(color: accentColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.55),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (shimmer)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accentColor.withValues(alpha: 0.0),
                            accentColor.withValues(alpha: 0.22),
                            accentColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(
                          duration: 2200.ms,
                          color: accentColor.withValues(alpha: 0.35),
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );

    if (heroTag == null) return tappable;
    return Hero(tag: heroTag!, child: tappable);
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => Shimmer.fromColors(
        baseColor: const Color(0xFF1E1630),
        highlightColor: const Color(0xFF3D2A5C),
        child: const ColoredBox(color: Color(0xFF1E1630)),
      ),
      errorWidget: (_, _, _) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DiscoverPremiumVisual.primary.withValues(alpha: 0.35),
              DiscoverPremiumVisual.backgroundMid,
            ],
          ),
        ),
      ),
    );
  }
}
