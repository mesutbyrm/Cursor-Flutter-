import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_ui_provider.dart';
import '../../services/voice_room_dj_player.dart';
import '../premium/voice_glass.dart';

/// Şu an çalan müzik — web ile aynı: duraklat, ses, kapat.
class VoiceRoomMusicMiniPlayer extends ConsumerWidget {
  const VoiceRoomMusicMiniPlayer({
    super.key,
    required this.dj,
    this.onTap,
    this.onSkip,
    this.onStop,
    this.canModerate = false,
  });

  final ChatRoomDjState dj;
  final VoidCallback? onTap;
  final VoidCallback? onSkip;
  final VoidCallback? onStop;
  final bool canModerate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = dj.nowPlaying ??
        (dj.musicQueue.isNotEmpty ? dj.musicQueue.first : null);
    if (track == null && !dj.playing) return const SizedBox.shrink();

    final playback = ref.watch(voiceRoomDjPlayerProvider).playback;
    final ui = ref.watch(voiceRoomUiProvider);
    final effectiveTrack = track ??
        MusicQueueItem(
          id: 'unknown',
          title: 'Şarkı yükleniyor…',
          youtubeUrl: dj.musicUrl ?? '',
          createdAt: DateTime.now(),
        );

    return ValueListenableBuilder<VoiceRoomDjPlayback>(
      valueListenable: playback,
      builder: (context, pb, _) {
        final showBar = dj.playing ||
            track != null ||
            dj.musicQueue.isNotEmpty ||
            pb.playing ||
            pb.paused;
        if (!showBar) return const SizedBox.shrink();

        final progress =
            pb.duration.inMilliseconds > 0 ? pb.progress : 0.0;
        final remaining =
            pb.duration.inMilliseconds > 0 ? _format(pb.remaining) : '—:—';
        final isPaused = pb.paused || (!pb.playing && dj.playing);

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
                  padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: _thumb(effectiveTrack),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎶 Şu an çalıyor',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                            Text(
                              effectiveTrack.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'İsteyen: ${effectiveTrack.requestedBy?.displayName ?? '—'} · $remaining',
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
                      _ControlButton(
                        color: const Color(0xFFFFC107),
                        icon: isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        onPressed: () => ref
                            .read(voiceRoomDjPlayerProvider)
                            .togglePause(),
                      ),
                      _ControlButton(
                        color: AppThemeColors.accentPurple,
                        icon: ui.backgroundMusicEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        onPressed: () => ref
                            .read(voiceRoomUiProvider.notifier)
                            .toggleBackgroundMusic(),
                      ),
                      _ControlButton(
                        color: AppThemeColors.liveRed,
                        icon: Icons.close_rounded,
                        onPressed: onStop ??
                            () => ref.read(voiceRoomDjPlayerProvider).stop(),
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
                    value: progress > 0 ? progress : null,
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

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}
