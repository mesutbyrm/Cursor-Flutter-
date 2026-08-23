import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_image_urls.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../home/domain/entities/home_trend_video_entity.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../home/presentation/theme/home_approved_design.dart';
import '../../../home/presentation/widgets/approved/home_section_title.dart';
import '../../../home/presentation/widgets/home_mystic_cover.dart';
import '../../../home/presentation/data/section_visual_catalog.dart';
import '../providers/shorts_providers.dart';
import '../utils/short_video_player_util.dart';

/// Hub sayfalarında yatay kısa video şeridi — `GET /api/short-videos?tab=foryou`.
class ShortsHubStrip extends ConsumerWidget {
  const ShortsHubStrip({
    super.key,
    this.title = 'Kısa Videolar',
    this.emoji = '🎬',
    this.actionLabel = 'Tümünü Gör >',
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.bottomSpacing = 12,
    this.thumbSize = HomeApprovedDesign.trendThumb,
    this.useHomeHeader = false,
    this.showWhenLoading = true,
  });

  final String title;
  final String emoji;
  final String actionLabel;
  final EdgeInsetsGeometry padding;
  final double bottomSpacing;
  final double thumbSize;
  final bool useHomeHeader;
  final bool showWhenLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videos = ref.watch(
      homeTrendVideosProvider.select((a) => (a.isLoading, a.hasError, a.valueOrNull)),
    );

    if (videos.$1 && videos.$3 == null) {
      if (!showWhenLoading) return const SizedBox.shrink();
      return Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: title,
              emoji: emoji,
              actionLabel: actionLabel,
              useHomeHeader: useHomeHeader,
              onAction: () => context.push('/shorts/explore'),
            ),
            SizedBox(
              height: thumbSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, _) => PremiumSkeleton(
                  width: thumbSize,
                  height: thumbSize,
                  borderRadius: BorderRadius.all(
                    Radius.circular(HomeApprovedDesign.cardRadius),
                  ),
                ),
              ),
            ),
            SizedBox(height: bottomSpacing),
          ],
        ),
      );
    }

    if (videos.$2) return const SizedBox.shrink();
    final items = videos.$3;
    if (items == null || items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            title: title,
            emoji: emoji,
            actionLabel: actionLabel,
            useHomeHeader: useHomeHeader,
            onAction: () => context.push('/shorts/explore'),
          ),
          RepaintBoundary(
            child: SizedBox(
              height: thumbSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _ShortsHubThumb(
                  index: i,
                  video: items[i],
                  size: thumbSize,
                  onTap: () => _openVideo(context, ref, items[i]),
                ),
              ),
            ),
          ),
          SizedBox(height: bottomSpacing),
        ],
      ),
    );
  }

  static void _openVideo(
    BuildContext context,
    WidgetRef ref,
    HomeTrendVideoEntity video,
  ) {
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
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.emoji,
    required this.actionLabel,
    required this.useHomeHeader,
    required this.onAction,
  });

  final String title;
  final String emoji;
  final String actionLabel;
  final bool useHomeHeader;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    if (useHomeHeader) {
      return HomeSectionTitle(
        emoji: emoji,
        title: title,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortsHubThumb extends StatelessWidget {
  const _ShortsHubThumb({
    required this.index,
    required this.video,
    required this.size,
    required this.onTap,
  });

  final int index;
  final HomeTrendVideoEntity video;
  final double size;
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

  static const _accents = [
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
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              HomeMysticCover(
                slug: SectionVisualCatalog.trendFallbackSlug(index),
                accent: _accents[index % _accents.length],
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
                      _formatCount(video.viewCount),
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
                      _formatCount(video.likesCount),
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

  static String _formatCount(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return '$n';
  }
}
