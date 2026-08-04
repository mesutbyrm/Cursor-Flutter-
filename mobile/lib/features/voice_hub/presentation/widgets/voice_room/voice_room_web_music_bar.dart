import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../providers/chat_room_providers.dart';
import '../../../music/presentation/providers/room_music_providers.dart';
import '../../services/voice_room_dj_player.dart';

/// Modern müzik oynatıcı — şu an çalan, isteyen, süre, kuyruk sayısı.
class VoiceRoomWebMusicBar extends ConsumerStatefulWidget {
  const VoiceRoomWebMusicBar({
    super.key,
    required this.dj,
    this.roomLiveKey,
    this.onPlayPause,
    this.onStop,
    this.onMuteToggle,
    this.onClose,
    this.onQueueTap,
    this.onSkipNext,
    this.musicMuted = false,
    this.isVideoMode = false,
    this.canControlMusic = false,
    this.showDebug = false,
  });

  final ChatRoomDjState dj;
  final String? roomLiveKey;
  final VoidCallback? onPlayPause;
  final VoidCallback? onStop;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onClose;
  final VoidCallback? onQueueTap;
  final VoidCallback? onSkipNext;
  final bool musicMuted;
  final bool isVideoMode;
  final bool canControlMusic;
  final bool showDebug;

  @override
  ConsumerState<VoiceRoomWebMusicBar> createState() =>
      _VoiceRoomWebMusicBarState();
}

class _VoiceRoomWebMusicBarState extends ConsumerState<VoiceRoomWebMusicBar> {
  double _volume = 1.0;

  @override
  Widget build(BuildContext context) {
    final dj = widget.dj;
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
    final liveKey = widget.roomLiveKey?.trim();
    final songState = liveKey != null && liveKey.isNotEmpty
        ? ref.watch(roomSongBlocProvider(liveKey)).state
        : null;
    final iframePlaying =
        songState?.hasTrack == true && songState!.current?.paused != true;
    final iframeProgress = songState?.progress ?? 0.0;

    return ValueListenableBuilder<VoiceRoomDjPlayback>(
      valueListenable: playback,
      builder: (context, pb, _) {
        return ValueListenableBuilder<VoiceRoomMusicDiagnostics>(
          valueListenable: diagnostics,
          builder: (context, diag, _) {
            final audioActive = pb.playing || iframePlaying;
            final hasDuration = pb.duration.inMilliseconds > 0 || iframeProgress > 0;
            final showPlaying =
                audioActive || (dj.playing && hasDuration) || loading;
            final effectiveVolume = widget.musicMuted ? 0.0 : _volume;
            final elapsed = hasDuration
                ? _format(pb.position)
                : '00:00';
            final total = displayTrack.duration?.isNotEmpty == true
                ? displayTrack.duration!
                : (hasDuration ? _format(pb.duration) : '—:—');
            final progress = iframeProgress > 0
                ? iframeProgress
                : (hasDuration && pb.duration.inMilliseconds > 0
                    ? pb.progress
                    : (loading ? null : 0.0));

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
                  padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.isVideoMode
                                ? Icons.music_video_rounded
                                : Icons.headphones_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.isVideoMode ? 'Videolu' : 'Sesli',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (loading)
                            const SizedBox(
                              width: 56,
                              height: 56,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: _thumb(displayTrack),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayTrack.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                if (artist.isNotEmpty)
                                  Text(
                                    artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.75),
                                    ),
                                  ),
                                Text(
                                  'İsteyen: $requester'
                                  '${waitingCount > 0 ? ' • Sırada: $waitingCount' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white.withValues(alpha: 0.62),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.onQueueTap != null && waitingCount > 0)
                            _BarIconButton(
                              onPressed: widget.onQueueTap,
                              color: const Color(0xFF4527A0),
                              icon: Icons.queue_music_rounded,
                              tooltip: 'Kuyruk',
                            ),
                          if (widget.onPlayPause != null) ...[
                            const SizedBox(width: 4),
                            _BarIconButton(
                              onPressed: widget.onPlayPause,
                              color: const Color(0xFFFF9800),
                              icon: audioActive
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              tooltip: audioActive ? 'Duraklat' : 'Devam et',
                            ),
                          ],
                          if (widget.canControlMusic && widget.onSkipNext != null) ...[
                            const SizedBox(width: 4),
                            _BarIconButton(
                              onPressed: widget.onSkipNext,
                              color: const Color(0xFF5E35B1),
                              icon: Icons.skip_next_rounded,
                              tooltip: 'Sonraki',
                            ),
                          ],
                          if (widget.canControlMusic && widget.onStop != null) ...[
                            const SizedBox(width: 4),
                            _BarIconButton(
                              onPressed: widget.onStop,
                              color: const Color(0xFF546E7A),
                              icon: Icons.stop_rounded,
                              tooltip: 'Durdur',
                            ),
                          ],
                          if (widget.onMuteToggle != null) ...[
                            const SizedBox(width: 4),
                            _BarIconButton(
                              onPressed: widget.onMuteToggle,
                              color: const Color(0xFF7B1FA2),
                              icon: effectiveVolume <= 0
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              tooltip: effectiveVolume <= 0 ? 'Sesi aç' : 'Sessiz',
                            ),
                          ],
                          if (widget.onClose != null) ...[
                            const SizedBox(width: 4),
                            _BarIconButton(
                              onPressed: widget.onClose,
                              color: const Color(0xFFC62828),
                              icon: Icons.close_rounded,
                              tooltip: 'Kapat',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            effectiveVolume <= 0
                                ? Icons.volume_off_rounded
                                : Icons.volume_down_rounded,
                            size: 14,
                            color: Colors.white54,
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 5,
                                ),
                              ),
                              child: Slider(
                                value: effectiveVolume,
                                min: 0,
                                max: 1,
                                activeColor: AppThemeColors.accentPink,
                                inactiveColor: Colors.white24,
                                onChanged: widget.musicMuted
                                    ? null
                                    : (v) {
                                        setState(() => _volume = v);
                                        unawaited(player.setVolumeLevel(v));
                                      },
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.volume_up_rounded,
                            size: 14,
                            color: Colors.white54,
                          ),
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
                      if (widget.showDebug) ...[
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
      return CanlifalNetworkImage(url: url, fit: BoxFit.cover);
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
