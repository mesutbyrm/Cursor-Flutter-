import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../bloc/room_song_bloc.dart';
import '../bloc/room_song_event.dart';
import '../bloc/room_song_state.dart';

/// TikTok/Bigo benzeri mini player — resmi YouTube IFrame Player API.
class RoomSongMiniPlayer extends StatefulWidget {
  const RoomSongMiniPlayer({
    super.key,
    required this.roomId,
    this.canControl = false,
    this.bottomInset = 72,
    this.muted = false,
    this.hidden = false,
  });

  final String roomId;
  final bool canControl;
  final double bottomInset;
  final bool muted;

  /// Yalnızca IFrame senkronu — görünür mini bar yok (web müzik bar / arka plan kullanılır).
  final bool hidden;

  @override
  State<RoomSongMiniPlayer> createState() => _RoomSongMiniPlayerState();
}

class _RoomSongMiniPlayerState extends State<RoomSongMiniPlayer> {
  YoutubePlayerController? _yt;
  String? _boundVideoId;
  Timer? _driftTimer;

  @override
  void initState() {
    super.initState();
    _driftTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      context.read<RoomSongBloc>().add(
            RoomSongSeekTick(DateTime.now().millisecondsSinceEpoch),
          );
    });
  }

  @override
  void didUpdateWidget(covariant RoomSongMiniPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muted != widget.muted) {
      final bloc = context.read<RoomSongBloc>();
      unawaited(_syncPlayer(bloc.state));
    }
  }

  @override
  void dispose() {
    _driftTimer?.cancel();
    _yt?.close();
    super.dispose();
  }

  Future<void> _syncPlayer(RoomSongState state) async {
    final song = state.current;
    if (song == null || !song.hasTrack) {
      _boundVideoId = null;
      await _yt?.close();
      _yt = null;
      return;
    }
    if (!song.isVideoRequest) {
      _boundVideoId = null;
      await _yt?.close();
      _yt = null;
      return;
    }

    final videoId = song.resolvedVideoId;
    if (videoId == null || videoId.isEmpty) {
      _boundVideoId = null;
      await _yt?.close();
      _yt = null;
      return;
    }

    if (_yt == null || _boundVideoId != videoId) {
      _boundVideoId = videoId;
      await _yt?.close();
      _yt = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: true,
          mute: false,
          playsInline: true,
          enableCaption: false,
        ),
      );
    }

    final c = _yt;
    if (c == null) return;
    final targetSec = state.current!.resolvedElapsedSeconds();
    final currentSec = await c.currentTime;
    final driftMs = ((currentSec - targetSec).abs() * 1000).round();
    if (driftMs > RoomSongBloc.driftThresholdMs || state.localDriftMs > RoomSongBloc.driftThresholdMs) {
      await c.seekTo(seconds: targetSec, allowSeekAhead: true);
    }
    if (state.current!.paused || widget.muted) {
      await c.pauseVideo();
    } else {
      await c.playVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoomSongBloc, RoomSongState>(
      listenWhen: (p, n) =>
          p.current?.videoId != n.current?.videoId ||
          p.current?.paused != n.current?.paused ||
          p.localDriftMs != n.localDriftMs,
      listener: (context, state) {
        unawaited(_syncPlayer(state));
      },
      buildWhen: (p, n) =>
          p.hasTrack != n.hasTrack ||
          p.miniExpanded != n.miniExpanded ||
          p.fullscreen != n.fullscreen ||
          p.current?.title != n.current?.title ||
          p.current?.paused != n.current?.paused ||
          p.progress != n.progress,
      builder: (context, state) {
        if (!state.hasTrack) return const SizedBox.shrink();
        if (state.current?.isVideoRequest != true) return const SizedBox.shrink();

        if (widget.hidden) {
          return Offstage(
            child: SizedBox(
              width: 1,
              height: 1,
              child: _yt != null ? YoutubePlayer(controller: _yt!) : null,
            ),
          );
        }

        if (state.fullscreen && _yt != null) {
          return Material(
            color: Colors.black,
            child: SafeArea(
              child: Stack(
                children: [
                  Center(child: YoutubePlayer(controller: _yt!)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context
                          .read<RoomSongBloc>()
                          .add(const RoomSongFullscreen(false)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final bottom = MediaQuery.paddingOf(context).bottom;
        final song = state.current!;
        final requester = song.ownerName?.trim().isNotEmpty == true
            ? song.ownerName!
            : 'Biri';

        return RepaintBoundary(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: EdgeInsets.fromLTRB(12, 0, 12, bottom + widget.bottomInset),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF121212).withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.miniExpanded && _yt != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 56,
                      child: YoutubePlayer(controller: _yt!),
                    ),
                  ),
                Row(
                  children: [
                    _Thumb(url: song.thumbnail),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title ?? 'Çalıyor',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'İsteyen: $requester',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: state.progress > 0 ? state.progress : null,
                            minHeight: 3,
                            backgroundColor: Colors.white12,
                            color: const Color(0xFF9B5CFF),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        state.miniExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => context.read<RoomSongBloc>().add(
                            RoomSongMiniExpanded(!state.miniExpanded),
                          ),
                    ),
                    if (widget.canControl)
                      IconButton(
                        icon: Icon(
                          song.paused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                        ),
                        onPressed: () => context.read<RoomSongBloc>().add(
                              song.paused
                                  ? const RoomSongUserResume()
                                  : const RoomSongUserPause(),
                            ),
                      ),
                    if (widget.canControl)
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: () => context
                            .read<RoomSongBloc>()
                            .add(const RoomSongUserSkip()),
                      ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white70),
                      onPressed: () => context
                          .read<RoomSongBloc>()
                          .add(const RoomSongFullscreen(true)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        height: 44,
        child: u != null && u.isNotEmpty
            ? CachedNetworkImage(imageUrl: u, fit: BoxFit.cover)
            : Container(
                color: const Color(0xFF2A2A2A),
                child: const Icon(Icons.music_note, color: Colors.white54),
              ),
      ),
    );
  }
}
