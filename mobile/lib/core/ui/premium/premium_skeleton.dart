import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_spacing.dart';

/// Skeleton loading — 2026 feed / kart shimmer.
class PremiumSkeleton extends StatelessWidget {
  const PremiumSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppSpacing.radiusMd),
        color: context.colors.surfaceElevated,
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          color: AppThemeColors.accentPurple.withValues(alpha: 0.12),
        );
  }
}

/// Canlı kart iskeleti.
class PremiumLiveCardSkeleton extends StatelessWidget {
  const PremiumLiveCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const PremiumSkeleton(width: 72, height: 88),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumSkeleton(
                width: 48,
                height: 14,
                borderRadius: BorderRadius.circular(6),
              ),
              const SizedBox(height: 8),
              PremiumSkeleton(width: double.infinity, height: 16),
              const SizedBox(height: 6),
              PremiumSkeleton(width: 120, height: 12),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sosyal post iskeleti.
class PremiumPostSkeleton extends StatelessWidget {
  const PremiumPostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PremiumSkeleton(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PremiumSkeleton(width: 100, height: 12),
                  const SizedBox(height: 6),
                  PremiumSkeleton(width: 60, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          PremiumSkeleton(
            width: double.infinity,
            height: 280,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ],
      ),
    );
  }
}
