import 'package:flutter/material.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../domain/entities/live_stream_viewer.dart';

/// Referans PK — üst sağda izleyici avatarları + sayı.
class LivePkViewerStrip extends StatelessWidget {
  const LivePkViewerStrip({
    super.key,
    required this.viewers,
    required this.totalCount,
    this.maxAvatars = 3,
    this.showRankBadges = false,
  });

  final List<LiveStreamViewer> viewers;
  final int totalCount;
  final int maxAvatars;
  final bool showRankBadges;

  @override
  Widget build(BuildContext context) {
    final shown = viewers.take(maxAvatars).toList();
    final count = totalCount > 0 ? totalCount : viewers.length;
    if (count <= 0 && shown.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (shown.isNotEmpty)
          SizedBox(
            width: 18.0 * shown.length + 8,
            height: 26,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < shown.length; i++)
                  Positioned(
                    left: i * 14.0,
                    child: _AvatarRing(
                      viewer: shown[i],
                      rank: showRankBadges ? i + 1 : null,
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(width: 6),
        const Icon(Icons.visibility_rounded, color: Colors.white70, size: 15),
        const SizedBox(width: 3),
        Text(
          _fmt(count),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({required this.viewer, this.rank});

  final LiveStreamViewer viewer;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final url = viewer.avatarUrl?.trim() ?? '';
    Color? rankColor;
    if (rank == 1) rankColor = const Color(0xFFFFD54F);
    if (rank == 2) rankColor = const Color(0xFFE0E0E0);
    if (rank == 3) rankColor = const Color(0xFFCD7F32);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: rankColor ?? Colors.white,
              width: rank != null ? 2 : 1.5,
            ),
          ),
          child: ClipOval(
            child: url.isNotEmpty
                ? CanlifalNetworkImage(url: url, fit: BoxFit.cover)
                : ColoredBox(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.7),
                    child: Center(
                      child: Text(
                        viewer.displayName.isNotEmpty
                            ? viewer.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        if (rank != null)
          Positioned(
            right: -4,
            bottom: -2,
            child: Container(
              width: 14,
              height: 14,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: rankColor ?? Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black87, width: 1),
              ),
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
