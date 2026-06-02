import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/presentation/utils/open_live_stream.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import 'home_section_header.dart';

class HomeLiveStreamsRow extends ConsumerWidget {
  const HomeLiveStreamsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(homeLiveStreamsProvider);

    return streams.when(
      loading: () => Column(
        children: [
          const HomeSectionHeader(
            title: 'Canlı Yayınlar',
            leadingDotColor: Color(0xFFFF3B5C),
          ),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const PremiumSkeleton(
                width: 140,
                height: 190,
                borderRadius: BorderRadius.all(Radius.circular(HomePalette.radiusCard)),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final live = items.where((s) => s.isLive).toList();
        if (live.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionHeader(
              title: 'Canlı Yayınlar',
              leadingDotColor: const Color(0xFFFF3B5C),
              onTrailing: () => context.go('/live'),
            ),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: live.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _LiveCard(
                  stream: live[i],
                  onTap: () => openLiveStreamNative(context, ref, live[i]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.stream, required this.onTap});

  final LiveStreamEntity stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final viewers = stream.viewerCount;
    final viewerLabel =
        viewers >= 1000 ? '${(viewers / 1000).toStringAsFixed(1)}K' : '$viewers';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 148,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HomePalette.radiusCard),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (stream.thumbnailUrl != null && stream.thumbnailUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: stream.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholder(),
                )
              else
                _placeholder(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 10,
                top: 10,
                child: LiveBadge(label: 'CANLI'),
              ),
              Positioned(
                left: 10,
                bottom: 36,
                child: Text(
                  viewerLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    if (stream.streamerName != null)
                      Text(
                        stream.streamerName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
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

  Widget _placeholder() {
    return Container(
      color: HomePalette.primary.withValues(alpha: 0.35),
      child: const Center(
        child: Icon(Icons.videocam_rounded, color: Colors.white54, size: 40),
      ),
    );
  }
}
