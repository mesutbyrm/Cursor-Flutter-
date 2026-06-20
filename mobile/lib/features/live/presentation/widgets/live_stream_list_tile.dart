import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../domain/entities/live_stream_entity.dart';

/// Canlı yayın kartı — premium 2026 keşfet.
class LiveStreamListTile extends StatelessWidget {
  const LiveStreamListTile({
    super.key,
    required this.stream,
    required this.onTap,
  });

  final LiveStreamEntity stream;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DiscoverGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: SizedBox(
              width: 88,
              height: 104,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Thumbnail(url: stream.thumbnailUrl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Row(
                      children: [
                        if (stream.isLive) const LiveBadge(compact: true),
                        if (stream.isPkLive) ...[
                          const SizedBox(width: 4),
                          _miniBadge('PK', const Color(0xFFFF6B6B)),
                        ],
                        if (stream.isVipHost) ...[
                          const SizedBox(width: 4),
                          _miniBadge('VIP', const Color(0xFFFFD700)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stream.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                if (stream.category != null && stream.category!.isNotEmpty)
                  Text(
                    stream.category!.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppThemeColors.accentPurple.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${stream.streamerName ?? 'Yayıncı'} · ${stream.viewerCount} izleyici',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          if (stream.isLive)
            Icon(
              Icons.play_circle_fill_rounded,
              color: AppThemeColors.accentPink.withValues(alpha: 0.9),
              size: 36,
            ),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        memCacheWidth: 220,
        errorWidget: (_, _, _) => const _Fallback(),
      );
    }
    return const _Fallback();
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppThemeColors.accentPurple.withValues(alpha: 0.5),
            context.scaffoldBg,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.live_tv_rounded, color: Colors.white54, size: 32),
      ),
    );
  }
}
