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
  });

  final List<LiveStreamViewer> viewers;
  final int totalCount;
  final int maxAvatars;

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
                    child: _AvatarRing(viewer: shown[i]),
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
  const _AvatarRing({required this.viewer});

  final LiveStreamViewer viewer;

  @override
  Widget build(BuildContext context) {
    final url = viewer.avatarUrl?.trim() ?? '';
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
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
    );
  }
}
