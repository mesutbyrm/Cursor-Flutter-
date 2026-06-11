import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../theme/voice_room_tokens.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../providers/chat_room_providers.dart';
import '../../services/voice_room_dj_player.dart';
import '../premium/voice_glass.dart';

/// Şu an çalan veya sıradaki müzik — kapak, ilerleme, oynatma kontrolleri.
class VoiceRoomMusicMiniPlayer extends ConsumerWidget {
  const VoiceRoomMusicMiniPlayer({
    super.key,
    required this.dj,
    this.onTap,
    this.onSkip,
    this.onPrevious,
    this.onPlayPause,
    this.onStop,
    this.onClose,
    this.onMuteToggle,
    this.canModerate = false,
    this.canControl = false,
    this.musicMuted = false,
    this.showClose = false,
  });

  final ChatRoomDjState dj;
  final VoidCallback? onTap;
  final VoidCallback? onSkip;
  final VoidCallback? onPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onStop;
  final VoidCallback? onClose;
  final VoidCallback? onMuteToggle;
  final bool canModerate;
  final bool canControl;
  final bool musicMuted;
  final bool showClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = dj.nowPlaying ??
        (dj.musicQueue.isNotEmpty ? dj.musicQueue.first : null);
    if (track == null && !dj.playing) return const SizedBox.shrink();
    final displayTrack = track ??
        MusicQueueItem(
          id: 'loading',
          title: 'Müzik yükleniyor…',
          youtubeUrl: dj.musicUrl ?? '',
          createdAt: DateTime.now(),
        );

    final player = ref.watch(voiceRoomDjPlayerProvider);
    final playback = player.playback;
    final diagnostics = player.diagnostics;
    final isQueuedOnly = !dj.playing && !playback.value.playing;

    return ValueListenableBuilder<VoiceRoomDjPlayback>(
      valueListenable: playback,
      builder: (context, pb, _) {
        return ValueListenableBuilder<VoiceRoomMusicDiagnostics>(
          valueListenable: diagnostics,
          builder: (context, diag, _) {
            return _buildPlayer(
              context,
              pb: pb,
              diag: diag,
              displayTrack: displayTrack,
              isQueuedOnly: isQueuedOnly,
              djName: _resolveDjName(dj),
            );
          },
        );
      },
    );
  }

  String _resolveDjName(ChatRoomDjState dj) {
    String djName = 'Admin';
    if (dj.activeDjId != null) {
      for (final u in dj.djUsers) {
        if (u.id == dj.activeDjId) {
          return u.displayName;
        }
      }
    } else if (dj.djUsers.isNotEmpty) {
      djName = dj.djUsers.first.displayName;
    }
    return djName;
  }

  Widget _buildPlayer(
    BuildContext context, {
    required VoiceRoomDjPlayback pb,
    required VoiceRoomMusicDiagnostics diag,
    required MusicQueueItem displayTrack,
    required bool isQueuedOnly,
    required String djName,
  }) {
        final isPlaying = dj.playing || pb.playing;
        final progress = isPlaying && pb.duration.inMilliseconds > 0
            ? pb.progress
            : (isQueuedOnly ? 0.0 : 0.08);
        final remaining = isPlaying && pb.duration.inMilliseconds > 0
            ? _format(pb.remaining)
            : (isQueuedOnly ? 'Sırada' : '—:—');
        final elapsed = isPlaying && pb.duration.inMilliseconds > 0
            ? _format(pb.position)
            : '00:00';
        final total = isPlaying && pb.duration.inMilliseconds > 0
            ? _format(pb.duration)
            : (displayTrack.duration ?? '—:—');

        final debugUrl = diag.resolvedStreamUrl ??
            diag.playbackSource ??
            dj.musicUrl ??
            displayTrack.youtubeUrl;
        final debugLine = _debugLine(diag, debugUrl);

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: VoiceGlass(
            borderRadius: 14,
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: onTap,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(10, 6, 10, 0),
                    child: Text(
                      'Şu An Çalan',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: AppThemeColors.coinGold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 4, 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
                            children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: _thumb(displayTrack),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTrack.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                color: Colors.white,
                              ),
                            ),
                            if (displayTrack.artistLine.isNotEmpty)
                              Text(
                                displayTrack.artistLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ),
                            Text(
                              'DJ: $djName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withValues(alpha: 0.62),
                              ),
                            ),
                            if (isQueuedOnly)
                              Text(
                                remaining,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppThemeColors.accentCyan
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                          ],
                        ),
                      ),
                            ],
                          ),
                        ),
                      ),
                      if (canControl && onPrevious != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          onPressed: onPrevious,
                          tooltip: 'Başa sar',
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 18,
                          ),
                        ),
                      if (canControl && onPlayPause != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          onPressed: onPlayPause,
                          tooltip: isPlaying ? 'Duraklat' : 'Oynat',
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      if (canControl && onStop != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          onPressed: onStop,
                          tooltip: 'Kuyruğu durdur',
                          icon: Icon(
                            Icons.stop_rounded,
                            color: Colors.white.withValues(alpha: 0.85),
                            size: 18,
                          ),
                        ),
                      if (canControl && onMuteToggle != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          onPressed: onMuteToggle,
                          tooltip: musicMuted ? 'Sesi aç' : 'Sesi kapat',
                          icon: Icon(
                            musicMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: musicMuted
                                ? AppThemeColors.liveRed.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.85),
                            size: 18,
                          ),
                        ),
                      if (isPlaying)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _MusicVisualizer(active: true),
                        ),
                      if (canControl && onSkip != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          onPressed: onSkip,
                          tooltip: 'Sonraki şarkı',
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      if (showClose && onClose != null)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          onPressed: onClose,
                          tooltip: 'Müziği kapat',
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
                if (debugLine != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
                    child: Text(
                      debugLine,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7,
                        height: 1.2,
                        fontFamily: 'monospace',
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
                  child: Row(
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
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: isQueuedOnly ? null : progress,
                              minHeight: 3,
                              backgroundColor: Colors.white12,
                              color: isQueuedOnly
                                  ? AppThemeColors.accentCyan.withValues(alpha: 0.7)
                                  : AppThemeColors.accentPink,
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
                ),
              ],
            ),
          ),
        );
  }

  String? _debugLine(VoiceRoomMusicDiagnostics diag, String? url) {
    final parts = <String>[];
    if (url != null && url.isNotEmpty) {
      parts.add('url=${_shortUrl(url)}');
    }
    if (diag.processingState != null) {
      parts.add('state=${diag.processingState}');
    }
    if (diag.isPlaying != null) {
      parts.add('playing=${diag.isPlaying}');
    }
    if (diag.muted == true) {
      parts.add('muted');
    }
    if (diag.lastError != null && diag.lastError!.isNotEmpty) {
      parts.add('err=${_shortUrl(diag.lastError!)}');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String _shortUrl(String raw) {
    final s = raw.trim();
    if (s.length <= 72) return s;
    return '${s.substring(0, 36)}…${s.substring(s.length - 28)}';
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

class _MusicVisualizer extends StatefulWidget {
  const _MusicVisualizer({required this.active});

  final bool active;

  @override
  State<_MusicVisualizer> createState() => _MusicVisualizerState();
}

class _MusicVisualizerState extends State<_MusicVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          return Row(
            children: List.generate(5, (i) {
              final wave = widget.active
                  ? 0.35 + ((_pulse.value + i * 0.18) % 1.0) * 0.65
                  : 0.2;
              final h = 4.0 + wave * 14.0;
              return Container(
                width: 3,
                height: h,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [VoiceRoomTokens.neonPink, VoiceRoomTokens.neonPurple],
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
