import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../domain/entities/home_trend_video_entity.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';
import '../../../../shorts/presentation/providers/shorts_providers.dart';

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
                video: videos[i],
                onTap: () async {
                  final id = videos[i].id;
                  try {
                    await ref
                        .read(shortsRepositoryProvider)
                        .recordView(id, watchedSec: 1);
                    ref.invalidate(homeTrendVideosProvider);
                  } catch (_) {}
                  if (context.mounted) context.push('/shorts?videoId=$id');
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
              if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty)
                CanlifalNetworkImage(
                  url: video.thumbnailUrl!,
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
