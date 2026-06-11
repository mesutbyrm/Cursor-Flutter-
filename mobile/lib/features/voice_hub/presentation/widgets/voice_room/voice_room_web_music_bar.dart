import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../providers/chat_room_providers.dart';
import '../../services/voice_room_dj_player.dart';

/// Web sesli oda ile aynı kompakt «Şu an çalıyor» şeridi — tek satır, pause/ses/kapat.
class VoiceRoomWebMusicBar extends ConsumerWidget {
  const VoiceRoomWebMusicBar({
    super.key,
    required this.dj,
    this.onPlayPause,
    this.onMuteToggle,
    this.onClose,
    this.musicMuted = false,
    this.showDebug = true,
  });

  final ChatRoomDjState dj;
  final VoidCallback? onPlayPause;
  final VoidCallback? onMuteToggle;
  final VoidCallback? onClose;
  final bool musicMuted;
  final bool showDebug;

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

    return ValueListenableBuilder<VoiceRoomDjPlayback>(
      valueListenable: playback,
      builder: (context, pb, _) {
        return ValueListenableBuilder<VoiceRoomMusicDiagnostics>(
          valueListenable: diagnostics,
          builder: (context, diag, _) {
            final audioActive = pb.playing;
            final showPlaying = audioActive || dj.playing;
            final elapsed = pb.duration.inMilliseconds > 0
                ? _format(pb.position)
                : '00:00';
            final statusLabel = showPlaying
                ? '🎶 Şu an çalıyor • $elapsed'
                : '🎶 Sırada bekliyor';

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6A1B9A).withValues(alpha: 0.88),
                      const Color(0xFF4A148C).withValues(alpha: 0.92),
                    ],
                  ),
                  border: Border.all(
                    color: AppThemeColors.accentPurple.withValues(alpha: 0.45),
                  ),
                  boxShadow: AppThemeColors.glowShadow(
                    AppThemeColors.accentPurple,
                    blur: 12,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _WaveBadge(active: showPlaying),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.78),
                                  ),
                                ),
                                Text(
                                  displayTrack.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (onPlayPause != null)
                            _BarIconButton(
                              onPressed: onPlayPause,
                              color: const Color(0xFFFF9800),
                              icon: audioActive
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              tooltip: audioActive ? 'Duraklat' : 'Oynat',
                            ),
                          if (onMuteToggle != null) ...[
                            const SizedBox(width: 4),
                            _BarIconButton(
                              onPressed: onMuteToggle,
                              color: const Color(0xFF7B1FA2),
                              icon: musicMuted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              tooltip: musicMuted ? 'Sesi aç' : 'Sesi kapat',
                            ),
                          ],
                          if (onClose != null) ...[
                            const SizedBox(width: 4),
                            _BarIconButton(
                              onPressed: onClose,
                              color: const Color(0xFFC62828),
                              icon: Icons.close_rounded,
                              tooltip: 'Müziği kapat',
                            ),
                          ],
                        ],
                      ),
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

  String _debugLine(
    VoiceRoomMusicDiagnostics diag,
    ChatRoomDjState dj,
    MusicQueueItem track,
  ) {
    final url = diag.resolvedStreamUrl ??
        diag.playbackSource ??
        dj.musicUrl ??
        track.youtubeUrl ??
        '';
    final parts = <String>[
      if (url.isNotEmpty) 'url=${_short(url)}',
      if (diag.processingState != null) 'state=${diag.processingState}',
      if (diag.isPlaying != null) 'playing=${diag.isPlaying}',
      if (diag.lastPhase != null) 'phase=${diag.lastPhase}',
      if (diag.lastError != null) 'err=${_short(diag.lastError!)}',
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
          width: 32,
          height: 32,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _WaveBadge extends StatefulWidget {
  const _WaveBadge({required this.active});

  final bool active;

  @override
  State<_WaveBadge> createState() => _WaveBadgeState();
}

class _WaveBadgeState extends State<_WaveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final wave = widget.active
                ? 0.35 + ((_pulse.value + i * 0.2) % 1.0) * 0.65
                : 0.25;
            return Container(
              width: 3,
              height: 6 + wave * 14,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFFFF0080), Color(0xFFB832FF)],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
