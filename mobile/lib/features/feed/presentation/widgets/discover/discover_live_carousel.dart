import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_design.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../live/domain/entities/live_stream_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../live/presentation/utils/open_live_stream.dart';
import 'discover_section_header.dart';

class DiscoverLiveCarousel extends ConsumerStatefulWidget {
  const DiscoverLiveCarousel({super.key});

  @override
  ConsumerState<DiscoverLiveCarousel> createState() =>
      _DiscoverLiveCarouselState();
}

class _DiscoverLiveCarouselState extends ConsumerState<DiscoverLiveCarousel> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveStreamsProvider);

    return live.when(
      loading: () => const SizedBox(
        height: AppDesign.liveCardHeight + 48,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      error: (_, _) => _DemoLiveSection(onPage: (i) => setState(() => _page = i)),
      data: (streams) {
        final onAir = streams.where((s) => s.isLive).take(3).toList();
        if (onAir.isEmpty) {
          return _DemoLiveSection(onPage: (i) => setState(() => _page = i));
        }
        return _LiveRowSection(
          streams: onAir,
          pageIndex: _page,
          onPageChanged: (i) => setState(() => _page = i),
          ref: ref,
        );
      },
    );
  }
}

class _LiveRowSection extends StatelessWidget {
  const _LiveRowSection({
    required this.streams,
    required this.pageIndex,
    required this.onPageChanged,
    required this.ref,
  });

  final List<LiveStreamEntity> streams;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoverSectionHeader(
          title: 'Canlı Yayınlar',
          actionLabel: 'Tümünü gör',
          onAction: () => context.go('/live'),
        ),
        SizedBox(
          height: AppDesign.liveCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: streams.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final stream = streams[i];
              return _LiveBroadcastCard(
                stream: stream,
                onOpen: () => openLiveStreamNative(context, ref, stream),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _PageDots(count: streams.length, index: pageIndex),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DemoLiveSection extends StatelessWidget {
  const _DemoLiveSection({required this.onPage});

  final ValueChanged<int> onPage;

  static const _homeLiveCount = 3;

  static final _demos = <_DemoLive>[
    _DemoLive(
      name: 'Özge',
      category: 'Müzik • Sohbet',
      viewers: 4892,
      extra: 128,
      image:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
    ),
    _DemoLive(
      name: 'Deniz',
      category: 'Oyun • Chat',
      viewers: 2104,
      extra: 64,
      image:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&q=80',
    ),
    _DemoLive(
      name: 'Ece',
      category: 'Sohbet',
      viewers: 982,
      extra: 42,
      image:
          'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DiscoverSectionHeader(
          title: 'Canlı Yayınlar',
          actionLabel: 'Tümünü gör',
          onAction: () => context.go('/live'),
        ),
        SizedBox(
          height: AppDesign.liveCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _homeLiveCount,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => _DemoLiveCard(demo: _demos[i]),
          ),
        ),
        const SizedBox(height: 14),
        _PageDots(count: _homeLiveCount, index: 0),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DemoLive {
  const _DemoLive({
    required this.name,
    required this.category,
    required this.viewers,
    required this.extra,
    required this.image,
  });

  final String name;
  final String category;
  final int viewers;
  final int extra;
  final String image;
}

class _LiveBroadcastCard extends StatelessWidget {
  const _LiveBroadcastCard({
    required this.stream,
    required this.onOpen,
  });

  final LiveStreamEntity stream;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return _LiveCardShell(
      onTap: onOpen,
      imageUrl: stream.thumbnailUrl,
      name: stream.streamerName ?? 'Yayıncı',
      category: stream.title,
      viewers: stream.viewerCount,
      extraViewers: 128,
    );
  }
}

class _DemoLiveCard extends StatelessWidget {
  const _DemoLiveCard({required this.demo});

  final _DemoLive demo;

  @override
  Widget build(BuildContext context) {
    return _LiveCardShell(
      onTap: () => context.go('/live'),
      imageUrl: demo.image,
      name: demo.name,
      category: demo.category,
      viewers: demo.viewers,
      extraViewers: demo.extra,
    );
  }
}

class _LiveCardShell extends StatelessWidget {
  const _LiveCardShell({
    required this.onTap,
    required this.imageUrl,
    required this.name,
    required this.category,
    required this.viewers,
    required this.extraViewers,
  });

  final VoidCallback onTap;
  final String? imageUrl;
  final String name;
  final String category;
  final int viewers;
  final int extraViewers;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDesign.liveCardWidth,
      height: AppDesign.liveCardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesign.radiusCard),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDesign.radiusCard),
              boxShadow: [
                BoxShadow(
                  color: AppDesign.accentPink.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDesign.radiusCard),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  else
                    _placeholder(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppDesign.liveRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 72,
                    child: const _AudioVisualizer(),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppDesign.accentCyan.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.remove_red_eye_outlined,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatCount(viewers),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _AvatarStack(extra: extraViewers),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppDesign.accentPurple.withValues(alpha: 0.5),
            AppDesign.bgBase,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.live_tv_rounded, color: Colors.white54, size: 48),
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}K';
    }
    return '$n';
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.extra});

  final int extra;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < 3; i++)
          Transform.translate(
            offset: Offset(-10.0 * i, 0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppDesign.bgBase, width: 1.5),
              ),
              child: UserAvatar(
                radius: 11,
                url:
                    'https://i.pravatar.cc/64?img=${10 + i}',
              ),
            ),
          ),
        Transform.translate(
          offset: const Offset(-30, 0),
          child: Text(
            '+$extra',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _AudioVisualizer extends StatelessWidget {
  const _AudioVisualizer();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _bar(10),
        const SizedBox(width: 3),
        _bar(16),
        const SizedBox(width: 3),
        _bar(8),
      ],
    );
  }

  Widget _bar(double h) {
    return Container(
      width: 4,
      height: h,
      decoration: BoxDecoration(
        color: AppDesign.accentPink,
        borderRadius: BorderRadius.circular(2),
        boxShadow: AppDesign.glowShadow(AppDesign.accentPink, blur: 8),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count.clamp(1, 8), (i) {
        final active = i == index % count;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 8,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: active
                ? AppDesign.accentPink
                : Colors.white.withValues(alpha: 0.18),
          ),
        );
      }),
    );
  }
}
