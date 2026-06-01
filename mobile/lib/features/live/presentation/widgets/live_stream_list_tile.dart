import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../domain/entities/live_stream_entity.dart';

/// Canlı yayın liste satırı — keşfet / canlı sekmesi.
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
              width: 72,
              height: 88,
              child: _Thumbnail(url: stream.thumbnailUrl),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stream.isLive) ...[
                  const LiveBadge(compact: true),
                  const SizedBox(height: 6),
                ],
                Text(
                  stream.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
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
        memCacheWidth: 200,
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
