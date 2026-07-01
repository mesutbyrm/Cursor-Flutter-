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

/// Profil sayfası iskeleti.
class PremiumProfileSkeleton extends StatelessWidget {
  const PremiumProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          PremiumSkeleton(
            width: double.infinity,
            height: 108,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 24),
          const PremiumSkeleton(
            width: 104,
            height: 104,
            borderRadius: BorderRadius.all(Radius.circular(52)),
          ),
          const SizedBox(height: 16),
          PremiumSkeleton(width: 180, height: 22),
          const SizedBox(height: 8),
          PremiumSkeleton(width: 120, height: 14),
          const SizedBox(height: 20),
          PremiumSkeleton(
            width: double.infinity,
            height: 88,
            borderRadius: BorderRadius.circular(16),
          ),
        ],
      ),
    );
  }
}

/// Mesaj listesi iskeleti.
class PremiumMessageListSkeleton extends StatelessWidget {
  const PremiumMessageListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final mine = i.isEven;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: PremiumSkeleton(
            width: mine ? 220 : 260,
            height: 52,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}

/// Kısa video feed tam ekran iskeleti.
class PremiumShortFeedSkeleton extends StatelessWidget {
  const PremiumShortFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: PremiumSkeleton(
              width: MediaQuery.sizeOf(context).width * 0.72,
              height: MediaQuery.sizeOf(context).height * 0.55,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Positioned(
            left: 16,
            right: 72,
            bottom: MediaQuery.paddingOf(context).bottom + 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PremiumSkeleton(width: 120, height: 14),
                const SizedBox(height: 8),
                PremiumSkeleton(width: double.infinity, height: 12),
                const SizedBox(height: 6),
                PremiumSkeleton(width: 180, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Keşfet / hashtag 2 sütun grid iskeleti.
class PremiumShortGridSkeleton extends StatelessWidget {
  const PremiumShortGridSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 9 / 14,
      ),
      itemCount: count,
      itemBuilder: (_, _) => const PremiumSkeleton(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    );
  }
}

/// Yatay kısa video şeridi iskeleti.
class PremiumShortStripSkeleton extends StatelessWidget {
  const PremiumShortStripSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, _) => const PremiumSkeleton(
          width: 110,
          height: 180,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }
}

/// Keşfet sayfası tam yükleme iskeleti.
class PremiumShortExploreSkeleton extends StatelessWidget {
  const PremiumShortExploreSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        PremiumSkeleton(width: double.infinity, height: 48),
        SizedBox(height: 20),
        PremiumShortStripSkeleton(),
        SizedBox(height: 20),
        PremiumShortStripSkeleton(),
        SizedBox(height: 20),
        PremiumShortGridSkeleton(count: 4),
      ],
    );
  }
}
