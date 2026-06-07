import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../feed/presentation/widgets/discover_premium_2026/discover_premium_visual.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/presentation/utils/open_live_stream.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import 'home_section_header.dart';

/// Ana sayfa — yatay kaydırmalı canlı yayın kartları (web ile aynı `/api/video-streams`).
class HomeLiveStreamsRow extends ConsumerWidget {
  const HomeLiveStreamsRow({super.key});

  static const _cardWidth = 268.0;
  static const _aspectRatio = 16 / 9;
  static const _eagerCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(homeLiveStreamsProvider);

    return streams.when(
      loading: () => _section(
        context,
        ref,
        child: SizedBox(
          height: _cardWidth / _aspectRatio,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, __) => PremiumSkeleton(
              width: _cardWidth,
              height: _cardWidth / _aspectRatio,
              borderRadius:
                  const BorderRadius.all(Radius.circular(HomePalette.radiusCard)),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        final live = items.where((s) => s.isLive).toList();
        if (live.isEmpty) return const SizedBox.shrink();
        return _section(
          context,
          ref,
          child: _LiveBroadcastList(streams: live),
        );
      },
    );
  }

  Widget _section(
    BuildContext context,
    WidgetRef ref, {
    required Widget child,
  }) {
    return Column(
      children: [
        HomeSectionHeader(
          title: 'Canlı Yayındakiler',
          leadingDotColor: AppThemeColors.liveRed,
          onTrailing: () => context.go('/live'),
        ),
        child,
      ],
    );
  }
}

class _LiveBroadcastList extends ConsumerStatefulWidget {
  const _LiveBroadcastList({required this.streams});

  final List<LiveStreamEntity> streams;

  @override
  ConsumerState<_LiveBroadcastList> createState() => _LiveBroadcastListState();
}

class _LiveBroadcastListState extends ConsumerState<_LiveBroadcastList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheLeading());
  }

  @override
  void didUpdateWidget(covariant _LiveBroadcastList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streams != widget.streams) {
      _precacheLeading();
    }
  }

  void _precacheLeading() {
    if (!mounted) return;
    final limit = widget.streams.length.clamp(0, HomeLiveStreamsRow._eagerCount);
    for (var i = 0; i < limit; i++) {
      final url = widget.streams[i].thumbnailUrl;
      if (url == null || url.isEmpty) continue;
      precacheImage(
        CachedNetworkImageProvider(url),
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = HomeLiveStreamsRow._cardWidth / HomeLiveStreamsRow._aspectRatio;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        cacheExtent: HomeLiveStreamsRow._cardWidth * HomeLiveStreamsRow._eagerCount,
        itemCount: widget.streams.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final stream = widget.streams[index];
          final eager = index < HomeLiveStreamsRow._eagerCount;
          return _LiveBroadcastCard(
            stream: stream,
            eagerLoad: eager,
            onTap: () => openLiveStreamNative(context, ref, stream),
          );
        },
      ),
    );
  }
}

class _LiveBroadcastCard extends StatelessWidget {
  const _LiveBroadcastCard({
    required this.stream,
    required this.onTap,
    this.eagerLoad = false,
  });

  final LiveStreamEntity stream;
  final VoidCallback onTap;
  final bool eagerLoad;

  @override
  Widget build(BuildContext context) {
    final cardWidth = HomeLiveStreamsRow._cardWidth;
    final cardHeight = cardWidth / HomeLiveStreamsRow._aspectRatio;
    final category = _displayCategory(stream);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HomePalette.radiusCard),
          boxShadow: DiscoverPremiumVisual.cardGlow(
            color: DiscoverPremiumVisual.accent,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(HomePalette.radiusCard),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _PreviewImage(
                url: stream.thumbnailUrl,
                eagerLoad: eagerLoad,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              const Positioned(
                top: 10,
                left: 10,
                child: LiveBadge(compact: true),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _ViewerPill(count: stream.viewerCount),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stream.streamerName ?? 'Yayıncı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stream.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (category != null) ...[
                      const SizedBox(height: 8),
                      _CategoryBadge(label: category),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _displayCategory(LiveStreamEntity stream) {
    final raw = stream.category?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return null;
  }
}

class _PreviewImage extends StatelessWidget {
  const _PreviewImage({required this.url, required this.eagerLoad});

  final String? url;
  final bool eagerLoad;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return _placeholder();
    }

    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      memCacheWidth: eagerLoad ? 720 : 480,
      fadeInDuration: eagerLoad ? Duration.zero : const Duration(milliseconds: 200),
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HomePalette.primary.withValues(alpha: 0.55),
            const Color(0xFF12082A),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.live_tv_rounded, color: Colors.white38, size: 48),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.remove_red_eye_outlined,
            size: 13,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            _formatViewers(count),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatViewers(int n) {
    if (n >= 1000000) {
      final m = n / 1000000;
      return '${m.toStringAsFixed(m >= 10 ? 0 : 1)}M';
    }
    if (n >= 1000) {
      final k = n / 1000;
      final text = k.toStringAsFixed(k >= 10 ? 0 : 1).replaceAll('.', ',');
      return '$text B';
    }
    return '$n';
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: HomePalette.primary.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
