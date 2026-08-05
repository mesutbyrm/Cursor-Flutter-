import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_image_urls.dart';

import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../domain/entities/home_trend_video_entity.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';
import '../../../../shorts/presentation/providers/shorts_providers.dart';
import '../../../../shorts/presentation/utils/short_video_player_util.dart';
import '../../data/section_visual_catalog.dart';
import '../home_mystic_cover.dart';

/// Ana sayfa — yüklenen kısa videolar (R2/CDN). YouTube trend içeriği gösterilmez.
class TrendingVideoSection extends ConsumerWidget {
  const TrendingVideoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(
      homeTrendVideosProvider.select((a) => (a.isLoading, a.hasError, a.valueOrNull)),
    );

    if (videos.$1 && videos.$3 == null) {
      return Column(
        children: [
          HomeSectionTitle(
            emoji: '🔥',
            title: 'Trend Videolar',
            actionLabel: 'Tümünü Gör >',
            onAction: () => context.push('/shorts/explore'),
          ),
          SizedBox(
            height: HomeApprovedDesign.trendThumb,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: HomeApprovedDesign.hPad,
              ),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, _) => const PremiumSkeleton(
                width: HomeApprovedDesign.trendThumb,
                height: HomeApprovedDesign.trendThumb,
                borderRadius: BorderRadius.all(
                  Radius.circular(HomeApprovedDesign.cardRadius),
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (videos.$2) return const SizedBox.shrink();
    final items = videos.$3;
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return _content(context, ref, items);
  }

  static Widget _content(
    BuildContext context,
    WidgetRef ref,
    List<HomeTrendVideoEntity> videos,
  ) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🔥',
          title: 'Trend Videolar',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.push('/shorts/explore'),
        ),
        RepaintBoundary(
          child: SizedBox(
            height: HomeApprovedDesign.trendThumb,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
              itemCount: videos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _TrendThumb(
                index: i,
                video: videos[i],
                onTap: () {
                  final video = videos[i];
                  final id = video.id;
                  unawaited(
                    preloadShortVideoUrl(
                      video.videoUrl ?? '',
                      videoId: id,
                      dio: ref.read(dioProvider),
                    ),
                  );
                  unawaited(
                    ref
                        .read(shortsRepositoryProvider)
                        .recordView(id, watchedSec: 1)
                        .then((_) => ref.invalidate(homeTrendVideosProvider))
                        .catchError((_) {}),
                  );
                  context.push('/shorts?videoId=$id');
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendThumb extends StatelessWidget {
  const _TrendThumb({
    required this.index,
    required this.video,
    required this.onTap,
  });

  final int index;
  final HomeTrendVideoEntity video;
  final VoidCallback onTap;

  String? get _networkThumbUrl {
    final raw = video.thumbnailUrl?.trim();
    if (raw != null && raw.isNotEmpty) {
      return CanlifalImageUrls.thumbnail(raw, width: 480);
    }
    final fromVideo = CanlifalImageUrls.thumbFromVideoUrl(video.videoUrl);
    if (fromVideo != null && fromVideo.isNotEmpty) {
      return CanlifalImageUrls.thumbnail(fromVideo, width: 480);
    }
    return null;
  }

  static const _trendAccents = [
    Color(0xFFB832FF),
    Color(0xFF8B5CF6),
    Color(0xFFFFD700),
    Color(0xFF38BDF8),
    Color(0xFFA855F7),
    Color(0xFFE11D48),
  ];

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
              HomeMysticCover(
                slug: SectionVisualCatalog.trendFallbackSlug(index),
                accent: _trendAccents[index % _trendAccents.length],
                networkUrl: _networkThumbUrl,
                thumbnailWidth: 480,
              ),
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
                right: 8,
                bottom: 8,
                child: Row(
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
                    const Spacer(),
                    const Icon(
                      Icons.favorite_rounded,
                      size: 12,
                      color: Color(0xFFFF4FD8),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatViews(video.likesCount),
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
