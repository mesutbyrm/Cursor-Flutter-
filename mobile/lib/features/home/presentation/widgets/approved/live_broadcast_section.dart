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
import '../premium_2026/home_horizontal_list.dart';
import '../premium_2026/home_section_shell.dart';
import 'live_stream_preview_media.dart';

/// Canlı yayın vitrini — premium kartlar, bağımsız yükleme/hata/boş durum.
class LiveBroadcastSection extends ConsumerWidget {
  const LiveBroadcastSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streams = ref.watch(
      homeLiveStreamsProvider.select(
        (a) => (a.isLoading, a.hasError, a.valueOrNull, a.error),
      ),
    );

    if (streams.$1 && streams.$3 == null) {
      return HomeSectionShell(
        emoji: '🔥',
        title: 'Canlı Yayındakiler',
        actionLabel: 'Tümünü Gör >',
        onAction: () => context.go('/live'),
        contentHeight: HomeApprovedDesign.liveCardH,
        loading: HomeHorizontalList(
          height: HomeApprovedDesign.liveCardH,
          itemCount: 3,
          itemBuilder: (_, _) => const PremiumSkeleton(
            width: HomeApprovedDesign.liveCardW,
            height: HomeApprovedDesign.liveCardH,
            borderRadius: BorderRadius.all(
              Radius.circular(HomeApprovedDesign.cardRadius),
            ),
          ),
        ),
      );
    }

    if (streams.$2) {
      return HomeSectionShell(
        emoji: '🔥',
        title: 'Canlı Yayındakiler',
        actionLabel: 'Tümünü Gör >',
        onAction: () => context.go('/live'),
        errorMessage: ApiException.userMessage(streams.$4 ?? 'Yüklenemedi'),
        onRetry: () => ref.invalidate(homeLiveStreamsProvider),
      );
    }

    final items = streams.$3;
    if (items == null || items.isEmpty) {
      return HomeSectionShell(
        emoji: '🔥',
        title: 'Canlı Yayındakiler',
        actionLabel: 'Tümünü Gör >',
        onAction: () => context.go('/live'),
        emptyIcon: Icons.videocam_outlined,
        emptyMessage: 'Şu anda canlı yayın yok',
      );
    }

    final live = items.where((s) => s.isLive).toList();
    final list = live.isNotEmpty ? live : items;
    if (list.isEmpty) {
      return HomeSectionShell(
        emoji: '🔥',
        title: 'Canlı Yayındakiler',
        actionLabel: 'Tümünü Gör >',
        onAction: () => context.go('/live'),
        emptyIcon: Icons.videocam_outlined,
        emptyMessage: 'Şu anda canlı yayın yok',
      );
    }

    return HomeSectionShell(
      emoji: '🔥',
      title: 'Canlı Yayındakiler',
      actionLabel: 'Tümünü Gör >',
      onAction: () => context.go('/live'),
      child: RepaintBoundary(
        child: HomeHorizontalList(
          height: HomeApprovedDesign.liveCardH,
          itemCount: list.take(12).length,
          itemBuilder: (context, i) {
            final stream = list[i];
            return _LiveCard(
              stream: stream,
              onTap: () => openLiveStreamNative(context, ref, stream),
            );
          },
        ),
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({
    required this.stream,
    required this.onTap,
  });

  final LiveStreamEntity stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Ink(
          width: HomeApprovedDesign.liveCardW,
          height: HomeApprovedDesign.liveCardH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            boxShadow: stream.isLive ? const [HomeApprovedDesign.liveGlow] : null,
            border: Border.all(
              color: stream.isLive
                  ? HomeApprovedDesign.purple.withValues(alpha: 0.35)
                  : HomeApprovedDesign.border,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                LiveStreamPreviewMedia(stream: stream),
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
                if (stream.isLive)
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
                      Text(
                        stream.streamerName ?? 'Yayıncı',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
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
          Icon(
            Icons.visibility_rounded,
            size: 11,
            color: Colors.white.withValues(alpha: 0.9),
          ),
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
