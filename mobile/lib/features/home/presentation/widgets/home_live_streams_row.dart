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
import 'home_glass_card.dart';
import 'home_section_header.dart';

class HomeLiveStreamsRow extends ConsumerWidget {
  const HomeLiveStreamsRow({super.key});

  static const _emptySlots = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(homeLiveStreamsProvider);

    return streams.when(
      loading: () => _section(
        context,
        child: SizedBox(
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
      ),
      error: (_, __) => _section(context, child: _buildList(context, ref, const [])),
      data: (items) => _section(
        context,
        child: _buildList(context, ref, items.where((s) => s.isLive).toList()),
      ),
    );
  }

  Widget _section(BuildContext context, {required Widget child}) {
    return Column(
      children: [
        HomeSectionHeader(
          title: 'Canlı Yayın Aç',
          leadingDotColor: const Color(0xFFFF3B5C),
          onTrailing: () => context.go('/live'),
        ),
        child,
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<LiveStreamEntity> live,
  ) {
    final count = 1 + (live.isEmpty ? _emptySlots : live.length.clamp(1, 8));

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _StartBroadcastCard(
              onTap: () => context.push('/live/prep'),
            );
          }
          final idx = i - 1;
          if (live.isEmpty) {
            return _EmptySlotCard(index: idx);
          }
          return _LiveCard(
            stream: live[idx],
            onTap: () => openLiveStreamNative(context, ref, live[idx]),
          );
        },
      ),
    );
  }
}

class _StartBroadcastCard extends StatelessWidget {
  const _StartBroadcastCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: HomeGlassCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        glowColor: const Color(0xFFFF4FD8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7B2FF7).withValues(alpha: 0.5),
            const Color(0xFF12082A),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4FD8), Color(0xFF7B2FF7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4FD8).withValues(alpha: 0.45),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              'Yayın Başlat',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: HomeGlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_outlined,
              size: 40,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 10),
            Text(
              'Boş Slot',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
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
                  border: Border.all(
                    color: const Color(0xFF7B2FF7).withValues(alpha: 0.5),
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
