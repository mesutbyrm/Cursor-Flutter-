import 'dart:math' as math;
import 'dart:ui';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme_colors.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../providers/chat_room_providers.dart';
import '../../providers/voice_room_ui_provider.dart';
import '../../services/voice_room_dj_player.dart';
import '../../theme/voice_room_tokens.dart';
import '../premium/voice_glass.dart';

/// Premium 2026 müzik kartı — web `music_started` / `music_stopped` ile senkron.
class VoiceRoomPremiumMusicCard extends ConsumerStatefulWidget {
  const VoiceRoomPremiumMusicCard({
    super.key,
    required this.room,
    required this.liveKey,
    required this.dj,
    required this.canClose,
    required this.listenerCount,
    this.likeCount = 0,
    this.onQueueTap,
  });

  final VoiceRoomEntity room;
  final String liveKey;
  final ChatRoomDjState dj;
  final bool canClose;
  final int listenerCount;
  final int likeCount;
  final VoidCallback? onQueueTap;

  @override
  ConsumerState<VoiceRoomPremiumMusicCard> createState() =>
      _VoiceRoomPremiumMusicCardState();
}

class _VoiceRoomPremiumMusicCardState
    extends ConsumerState<VoiceRoomPremiumMusicCard>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _vinylCtrl;
  late final AnimationController _rgbCtrl;
  late final AnimationController _waveCtrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  var _visible = false;
  String? _shownTrackId;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _vinylCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _rgbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _vinylCtrl.dispose();
    _rgbCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  MusicQueueItem? get _track =>
      widget.dj.nowPlaying ??
      (widget.dj.musicQueue.isNotEmpty ? widget.dj.musicQueue.first : null);

  bool _shouldShow(VoiceRoomMusicSessionState session) {
    final t = _track;
    if (t == null && !widget.dj.playing) return false;
    return !session.dismissed && !session.userDismissedPlayer;
  }

  void _syncVisibility(bool show) {
    if (show && !_visible) {
      _visible = true;
      _enterCtrl.forward(from: 0);
    } else if (!show && _visible) {
      _enterCtrl.reverse().then((_) {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  void _syncVinyl(bool playing) {
    if (playing) {
      if (!_vinylCtrl.isAnimating) _vinylCtrl.repeat();
    } else {
      _vinylCtrl.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicSession = ref.watch(voiceRoomMusicSessionProvider);
    final show = _shouldShow(musicSession);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncVisibility(show);
      _syncVinyl(widget.dj.playing);
      final id = _track?.id;
      if (id != null && id != _shownTrackId) {
        _shownTrackId = id;
      }
    });

    if (!_visible && !show) return const SizedBox.shrink();

    final track = _track ??
        MusicQueueItem(
          id: 'loading',
          title: 'Müzik yükleniyor…',
          youtubeUrl: widget.dj.musicUrl ?? '',
          createdAt: DateTime.now(),
        );
    final player = ref.watch(voiceRoomDjPlayerProvider);
    final musicMuted = !ref.watch(voiceRoomUiProvider).backgroundMusicEnabled;
    final width = MediaQuery.sizeOf(context).width;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 4),
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _rgbCtrl,
              builder: (context, child) {
                final hue = _rgbCtrl.value;
                return Container(
                  width: width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(VoiceRoomTokens.neonPink, VoiceRoomTokens.neonBlue, hue)!,
                        Color.lerp(VoiceRoomTokens.neonPurple, VoiceRoomTokens.neonPink, 1 - hue)!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(1.2),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: VoiceGlass(
                    borderRadius: 18,
                    backgroundColor: Colors.black.withValues(alpha: 0.55),
                    borderColor: Colors.white.withValues(alpha: 0.14),
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: ValueListenableBuilder<VoiceRoomDjPlayback>(
                      valueListenable: player.playback,
                      builder: (context, pb, _) {
                        final isPlaying = widget.dj.playing || pb.playing;
                        final progress = pb.duration.inMilliseconds > 0
                            ? pb.progress.clamp(0.0, 1.0)
                            : 0.0;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _VinylCover(
                                  track: track,
                                  spin: _vinylCtrl,
                                  playing: isPlaying,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 320),
                                        child: Text(
                                          track.title,
                                          key: ValueKey(track.id),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            color: Colors.white,
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                      if (track.artistLine.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          track.artistLine,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white.withValues(alpha: 0.78),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      _RequesterRow(track: track),
                                      const SizedBox(height: 8),
                                      _WaveformBars(controller: _waveCtrl, active: isPlaying),
                                    ],
                                  ),
                                ),
                                if (widget.canClose)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () async {
                                      await ref
                                          .read(
                                            voiceRoomLiveProvider(widget.liveKey)
                                                .notifier,
                                          )
                                          .stopMusic();
                                    },
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                    tooltip: 'Müziği durdur',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: isPlaying && pb.duration.inMilliseconds > 0
                                    ? progress
                                    : null,
                                minHeight: 4,
                                backgroundColor: Colors.white12,
                                color: AppThemeColors.accentPink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  _fmt(pb.position),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  pb.duration.inMilliseconds > 0
                                      ? _fmt(pb.duration)
                                      : (track.duration ?? '--:--'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _StatChip(
                                  icon: Icons.favorite_rounded,
                                  label: '${widget.likeCount}',
                                  color: AppThemeColors.liveRed,
                                ),
                                const SizedBox(width: 8),
                                _StatChip(
                                  icon: Icons.headphones_rounded,
                                  label: '${widget.listenerCount}',
                                  color: AppThemeColors.accentCyan,
                                ),
                                const Spacer(),
                                if (musicMuted)
                                  Text(
                                    'Sessiz',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => ref
                                      .read(voiceRoomUiProvider.notifier)
                                      .toggleBackgroundMusic(),
                                  icon: Icon(
                                    musicMuted
                                        ? Icons.volume_off_rounded
                                        : Icons.volume_up_rounded,
                                    color: Colors.white70,
                                    size: 20,
                                  ),
                                ),
                                if (widget.onQueueTap != null)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: widget.onQueueTap,
                                    icon: const Icon(
                                      Icons.queue_music_rounded,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _VinylCover extends StatelessWidget {
  const _VinylCover({
    required this.track,
    required this.spin,
    required this.playing,
  });

  final MusicQueueItem track;
  final AnimationController spin;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width > 600 ? 96.0 : 84.0;
    return RotationTransition(
      turns: spin,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: VoiceRoomTokens.neonRing,
          boxShadow: [
            BoxShadow(
              color: VoiceRoomTokens.neonPink.withValues(alpha: playing ? 0.45 : 0.2),
              blurRadius: 16,
            ),
          ],
        ),
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF111018),
          ),
          padding: const EdgeInsets.all(3),
          child: ClipOval(
            child: _cover(track),
          ),
        ),
      ),
    );
  }

  Widget _cover(MusicQueueItem track) {
    final url = track.thumbUrl;
    if (url != null && url.isNotEmpty) {
      return CanlifalNetworkImage(url: url, fit: BoxFit.cover);
    }
    return ColoredBox(
      color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.35),
      child: const Icon(Icons.album_rounded, color: Colors.white54, size: 36),
    );
  }
}

class _RequesterRow extends StatelessWidget {
  const _RequesterRow({required this.track});

  final MusicQueueItem track;

  @override
  Widget build(BuildContext context) {
    final user = track.requestedBy;
    final name = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : (user?.name.trim().isNotEmpty == true ? user!.name.trim() : 'Anonim');
    final avatar = user?.image?.trim();
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: VoiceRoomTokens.neonPurple.withValues(alpha: 0.4),
          backgroundImage:
              avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar == null || avatar.isEmpty
              ? const Icon(Icons.person_rounded, size: 14, color: Colors.white70)
              : null,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'İsteyen: $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppThemeColors.coinGold.withValues(alpha: 0.95),
            ),
          ),
        ),
      ],
    );
  }
}

class _WaveformBars extends StatelessWidget {
  const _WaveformBars({required this.controller, required this.active});

  final AnimationController controller;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return SizedBox(
            height: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(24, (i) {
                final phase = (controller.value + i * 0.07) % 1.0;
                final h = active
                    ? 4 + math.sin(phase * math.pi * 2) * 8 + 6
                    : 4.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.6),
                    child: Container(
                      height: h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            VoiceRoomTokens.neonPink.withValues(alpha: 0.85),
                            VoiceRoomTokens.neonBlue.withValues(alpha: 0.85),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
