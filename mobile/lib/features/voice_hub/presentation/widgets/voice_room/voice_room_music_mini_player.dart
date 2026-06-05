import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../providers/chat_room_providers.dart';
import '../../services/voice_room_dj_player.dart';
import '../premium/voice_glass.dart';

/// Şu an çalan müzik — kapak, ilerleme, isteyen.
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

    return ValueListenableBuilder<VoiceRoomDjPlayback>(
      valueListenable: playback,
      builder: (context, pb, _) {
        if (!dj.playing && !pb.playing) return const SizedBox.shrink();
        final progress =
            pb.duration.inMilliseconds > 0 ? pb.progress : 0.08;
        final remaining =
            pb.duration.inMilliseconds > 0 ? _format(pb.remaining) : '—:—';
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
          child: VoiceGlass(
            borderRadius: 16,
            padding: EdgeInsets.zero,
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: _thumb(track),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            if (track.artistLine.isNotEmpty)
                              Text(
                                track.artistLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ),
                            Text(
                              'İsteyen: ${track.requestedBy?.displayName ?? '—'} · $remaining',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canModerate && onSkip != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: onSkip,
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Colors.white12,
                    color: AppThemeColors.accentPink,
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
      child: const Icon(Icons.music_note_rounded, color: Colors.white54),
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
