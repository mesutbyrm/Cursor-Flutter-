import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../providers/chat_room_providers.dart';
import '../../services/voice_room_dj_player.dart';
import '../premium/voice_glass.dart';

/// Şu an çalan veya sıradaki müzik — kapak, ilerleme, isteyen.
class VoiceRoomMusicMiniPlayer extends ConsumerWidget {
  const VoiceRoomMusicMiniPlayer({
    super.key,
    required this.dj,
    this.onTap,
    this.onSkip,
    this.canModerate = false,
  });

  final ChatRoomDjState dj;
  final VoidCallback? onTap;
  final VoidCallback? onSkip;
  final bool canModerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = dj.nowPlaying ??
        (dj.musicQueue.isNotEmpty ? dj.musicQueue.first : null);
    if (track == null) return const SizedBox.shrink();

    final playback = ref.watch(voiceRoomDjPlayerProvider).playback;
    final isQueuedOnly = !dj.playing && !playback.value.playing;

    return ValueListenableBuilder<VoiceRoomDjPlayback>(
      valueListenable: playback,
      builder: (context, pb, _) {
        final isPlaying = dj.playing || pb.playing;
        final progress = isPlaying && pb.duration.inMilliseconds > 0
            ? pb.progress
            : (isQueuedOnly ? 0.0 : 0.08);
        final remaining = isPlaying && pb.duration.inMilliseconds > 0
            ? _format(pb.remaining)
            : (isQueuedOnly ? 'Sırada' : '—:—');
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: VoiceGlass(
            borderRadius: 14,
            padding: EdgeInsets.zero,
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: _thumb(track),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                            if (track.artistLine.isNotEmpty)
                              Text(
                                track.artistLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ),
                            Text(
                              isQueuedOnly
                                  ? 'İsteyen: ${track.requestedBy?.displayName ?? '—'} · $remaining'
                                  : 'İsteyen: ${track.requestedBy?.displayName ?? '—'} · $remaining',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8,
                                color: isQueuedOnly
                                    ? AppThemeColors.accentCyan
                                        .withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPlaying)
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            size: 16,
                            color: AppThemeColors.accentPink
                                .withValues(alpha: 0.95),
                          ),
                        ),
                      if (canModerate && onSkip != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: onSkip,
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(14),
                  ),
                  child: LinearProgressIndicator(
                    value: isQueuedOnly ? null : progress,
                    minHeight: 2,
                    backgroundColor: Colors.white12,
                    color: isQueuedOnly
                        ? AppThemeColors.accentCyan.withValues(alpha: 0.7)
                        : AppThemeColors.accentPink,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _thumb(MusicQueueItem track) {
    final url = track.thumbUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
    }
    return ColoredBox(
      color: AppThemeColors.accentPurple.withValues(alpha: 0.4),
      child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 18),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
