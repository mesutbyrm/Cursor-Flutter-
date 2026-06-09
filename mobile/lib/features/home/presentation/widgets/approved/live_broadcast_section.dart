import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../../../core/ui/premium/live_badge.dart';
import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../live/domain/entities/live_stream_entity.dart';
import '../../../../live/presentation/utils/open_live_stream.dart';
import '../../providers/home_providers.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Onaylı mockup — 3:4 dikey canlı yayın kartları.
class LiveBroadcastSection extends ConsumerWidget {
  const LiveBroadcastSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(homeLiveStreamsProvider);

    return streams.when(
      loading: () => Column(
        children: [
          HomeSectionTitle(
            emoji: '🔥',
            title: 'Canlı Yayındakiler',
            actionLabel: 'Tümünü Gör >',
            onAction: () => context.go('/live'),
          ),
          SizedBox(
            height: HomeApprovedDesign.liveCardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, __) => const PremiumSkeleton(
                width: HomeApprovedDesign.liveCardW,
                height: HomeApprovedDesign.liveCardH,
                borderRadius: BorderRadius.all(
                  Radius.circular(HomeApprovedDesign.cardRadius),
                ),
              ),
            ),
          ),
        ],
      ),
      error: (e, _) => _emptyOrError(context, ApiException.userMessage(e)),
      data: (items) {
        final live = items.where((s) => s.isLive).toList();
        final list = live.isNotEmpty ? live : items;
        if (list.isEmpty) return _emptyOrError(context, null);
        return _content(context, ref, list.take(12).toList());
      },
    );
  }

  static Widget _content(
    BuildContext context,
    WidgetRef ref,
    List<LiveStreamEntity> streams,
  ) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🔥',
          title: 'Canlı Yayındakiler',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.go('/live'),
        ),
        SizedBox(
          height: HomeApprovedDesign.liveCardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: streams.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _LiveCard(
              stream: streams[i],
              eager: i < 5,
              onTap: () => openLiveStreamNative(context, ref, streams[i]),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _emptyOrError(BuildContext context, String? message) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🔥',
          title: 'Canlı Yayındakiler',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.go('/live'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeApprovedDesign.hPad,
            vertical: 12,
          ),
          child: Text(
            message ?? 'Şu an canlı yayın yok.',
            style: TextStyle(
              fontSize: 13,
              color: HomeApprovedDesign.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.stream,
    required this.onTap,
    this.eager = false,
  });

  final LiveStreamEntity stream;
  final VoidCallback onTap;
  final bool eager;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: HomeApprovedDesign.liveCardW,
        height: HomeApprovedDesign.liveCardH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          boxShadow: const [HomeApprovedDesign.liveGlow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (stream.thumbnailUrl != null && stream.thumbnailUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: stream.thumbnailUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: eager ? 480 : 320,
                  fadeInDuration: eager ? Duration.zero : const Duration(milliseconds: 180),
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
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
              const Positioned(
                top: 8,
                left: 8,
                child: LiveBadge(compact: true),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _ViewerPill(count: stream.viewerCount),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            stream.streamerName ?? 'Yayıncı',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stream.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.85),
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
    return const ColoredBox(
      color: HomeApprovedDesign.surface,
      child: Center(
        child: Icon(Icons.live_tv_rounded, color: Colors.white24, size: 40),
      ),
    );
  }
}

class _ViewerPill extends StatelessWidget {
  const _ViewerPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👁', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(
            _format(count),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static String _format(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}K';
    }
    return '$n';
  }
}
