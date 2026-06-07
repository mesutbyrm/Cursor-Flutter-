import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../domain/entities/home_trend_video_entity.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Onaylı mockup — kare trend video küçük resimleri.
class TrendingVideoSection extends ConsumerWidget {
  const TrendingVideoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(homeTrendVideosProvider);

    return videos.when(
      loading: () => Column(
        children: [
          HomeSectionTitle(
            emoji: '🔥',
            title: 'Trend Videolar',
            actionLabel: 'Tümünü Gör >',
            onAction: () => context.go('/social'),
          ),
          SizedBox(
            height: HomeApprovedDesign.trendThumb,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => const PremiumSkeleton(
                width: HomeApprovedDesign.trendThumb,
                height: HomeApprovedDesign.trendThumb,
                borderRadius: BorderRadius.all(
                  Radius.circular(HomeApprovedDesign.cardRadius),
                ),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => _content(context, _fallbackVideos),
      data: (items) {
        final list = items.isNotEmpty ? items : _fallbackVideos;
        return _content(context, list);
      },
    );
  }

  static Widget _content(BuildContext context, List<HomeTrendVideoEntity> videos) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🔥',
          title: 'Trend Videolar',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.go('/social'),
        ),
        SizedBox(
          height: HomeApprovedDesign.trendThumb,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: videos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _TrendThumb(
              video: videos[i],
              onTap: () => context.go('/social'),
            ),
          ),
        ),
      ],
    );
  }

  static const _fallbackVideos = [
    HomeTrendVideoEntity(
      id: 'demo-1',
      title: 'Tarot Rehberi',
      channelName: 'Canlifal',
      viewCount: 2400,
    ),
    HomeTrendVideoEntity(
      id: 'demo-2',
      title: 'Kahve Falı',
      channelName: 'Canlifal',
      viewCount: 1800,
    ),
    HomeTrendVideoEntity(
      id: 'demo-3',
      title: 'Astroloji',
      channelName: 'Canlifal',
      viewCount: 920,
    ),
  ];
}

class _TrendThumb extends StatelessWidget {
  const _TrendThumb({required this.video, required this.onTap});

  final HomeTrendVideoEntity video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: SizedBox(
          width: HomeApprovedDesign.trendThumb,
          height: HomeApprovedDesign.trendThumb,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (video.thumbnailUrl != null)
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl!,
                  fit: BoxFit.cover,
                )
              else
                const ColoredBox(color: HomeApprovedDesign.surface),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatViews(video.viewCount),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatViews(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return '$n';
  }
}
