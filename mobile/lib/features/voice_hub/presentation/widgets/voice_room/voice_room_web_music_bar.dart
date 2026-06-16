import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../providers/chat_room_providers.dart';
import '../../services/voice_room_dj_player.dart';

/// Modern müzik oynatıcı — şu an çalan, isteyen, süre, kuyruk sayısı.
class VoiceRoomWebMusicBar extends ConsumerWidget {
  const VoiceRoomWebMusicBar({
    super.key,
    required this.dj,
    this.onPlayPause,
    this.onMuteToggle,
    this.onClose,
    this.musicMuted = false,
    this.canControlMusic = false,
    this.showDebug = false,
  });

  final ChatRoomDjState dj;
  final VoidCallback? onPlayPause;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onClose;
  final bool musicMuted;
  final bool canControlMusic;
  final bool showDebug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = dj.nowPlaying ??
        (dj.musicQueue.isNotEmpty ? dj.musicQueue.first : null);
    final loading = track == null && dj.playing;
    if (track == null && !dj.playing && !loading) {
      return const SizedBox.shrink();
    }

    final displayTrack = track ??
        MusicQueueItem(
          id: 'loading',
          title: 'Müzik yükleniyor…',
          youtubeUrl: dj.musicUrl ?? '',
          createdAt: DateTime.now(),
        );

    final waitingCount = _waitingCount(dj);
    final requester = displayTrack.requestedBy?.displayName ?? '—';
    final artist = displayTrack.uploader?.trim().isNotEmpty == true
        ? displayTrack.uploader!
        : (displayTrack.artistLine.isNotEmpty
            ? displayTrack.artistLine.split(' • ').first
            : '');

    final player = ref.watch(voiceRoomDjPlayerProvider);
    final playback = player.playback;
    final diagnostics = player.diagnostics;

    return ValueListenableBuilder<VoiceRoomDjPlayback>(
      valueListenable: playback,
      builder: (context, pb, _) {
        return ValueListenableBuilder<VoiceRoomMusicDiagnostics>(
          valueListenable: diagnostics,
          builder: (context, diag, _) {
            final audioActive = pb.playing;
            final hasDuration = pb.duration.inMilliseconds > 0;
            final showPlaying =
                audioActive || (dj.playing && hasDuration) || loading;
            final elapsed = hasDuration
                ? _format(pb.position)
                : '00:00';
            final total = displayTrack.duration?.isNotEmpty == true
                ? displayTrack.duration!
                : (hasDuration ? _format(pb.duration) : '—:—');
            final progress = hasDuration && pb.duration.inMilliseconds > 0
                ? pb.progress
                : (loading ? null : 0.0);

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6A1B9A).withValues(alpha: 0.92),
                      const Color(0xFF311B92).withValues(alpha: 0.95),
                    ],
                  ),
                  border: Border.all(
                    color: AppThemeColors.accentPurple.withValues(alpha: 0.5),
                  ),
                  boxShadow: AppThemeColors.glowShadow(
                    AppThemeColors.accentPurple,
                    blur: 14,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (loading)
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: _thumb(displayTrack),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  showPlaying
                                      ? 'Şu An Çalıyor'
                                      : 'Sırada',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppThemeColors.coinGold
                                        .withValues(alpha: 0.95),
                                  ),
                                ),
                                Text(
                                  artist.isNotEmpty
                                      ? '$artist — ${displayTrack.title}'
                                      : displayTrack.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'İsteyen: $requester • $total'
                                  '${waitingCount > 0 ? ' • Sırada: $waitingCount' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white.withValues(alpha: 0.68),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canControlMusic && onPlayPause != null)
                            _BarIconButton(
                              onPressed: onPlayPause,
                              color: const Color(0xFFFF9800),
                              icon: audioActive
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              tooltip: audioActive ? 'Duraklat' : 'Devam et',
                            ),
                          if (onMuteToggle != null) ...[
                            const SizedBox(width: 4),
                            _BarIconButton(
                              onPressed: onMuteToggle,
                              color: const Color(0xFF7B1FA2),
                              icon: musicMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              tooltip: musicMuted ? 'Sesi aç' : 'Hoparlör',
                            ),
                          ],
                          if (canControlMusic && onClose != null) ...[
                            const SizedBox(width: 4),
                            _BarIconButton(
                              onPressed: onClose,
                              color: const Color(0xFFC62828),
                              icon: Icons.close_rounded,
                              tooltip: 'Kapat',
                            ),
                          ],
                        ],
                      ),
                      if (showPlaying && !loading) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              elapsed,
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 3,
                                    backgroundColor: Colors.white12,
                                    color: AppThemeColors.accentPink,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              total,
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (showDebug) ...[
                        const SizedBox(height: 4),
                        Text(
                          _debugLine(diag, dj, displayTrack),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 7,
                            height: 1.15,
                            fontFamily: 'monospace',
                            color: Colors.white.withValues(alpha: 0.42),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _waitingCount(ChatRoomDjState dj) {
    final npId = dj.nowPlaying?.id;
    if (npId == null) {
      return dj.musicQueue.length > 1 ? dj.musicQueue.length - 1 : 0;
    }
    return dj.musicQueue.where((e) => e.id != npId).length;
  }

  Widget _thumb(MusicQueueItem track) {
    final url = track.thumbUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
    }
    return ColoredBox(
      color: AppThemeColors.accentPurple.withValues(alpha: 0.45),
      child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 20),
    );
  }

  String _debugLine(
    VoiceRoomMusicDiagnostics diag,
    ChatRoomDjState dj,
    MusicQueueItem track,
  ) {
    final url = diag.resolvedStreamUrl ??
        diag.playbackSource ??
        dj.musicUrl ??
        track.youtubeUrl;
    final parts = <String>[
      if (url.isNotEmpty) 'url=${_short(url)}',
      if (diag.processingState != null) 'state=${diag.processingState}',
      if (diag.isPlaying != null) 'playing=${diag.isPlaying}',
    ];
    return parts.join(' · ');
  }

  String _short(String raw) {
    final s = raw.trim();
    if (s.length <= 64) return s;
    return '${s.substring(0, 30)}…${s.substring(s.length - 22)}';
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.onPressed,
    required this.color,
    required this.icon,
    required this.tooltip,
  });

  final VoidCallback? onPressed;
  final Color color;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
