import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_providers.dart';
import '../utils/short_video_player_util.dart';
import 'short_video_actions_rail.dart';

class ShortVideoPageTile extends ConsumerStatefulWidget {
  const ShortVideoPageTile({
    super.key,
    required this.video,
    required this.isActive,
    required this.onVideoUpdated,
  });

  final ShortVideoEntity video;
  final bool isActive;
  final ValueChanged<ShortVideoEntity> onVideoUpdated;

  @override
  ConsumerState<ShortVideoPageTile> createState() => _ShortVideoPageTileState();
}

class _ShortVideoPageTileState extends ConsumerState<ShortVideoPageTile> {
  VideoPlayerController? _controller;
  var _loading = true;
  var _error = false;
  Timer? _viewTimer;
  var _viewSent = false;
  var _watchedSec = 0.0;

  @override
  void initState() {
    super.initState();
    _viewSent = widget.video.viewedByMe;
    _init();
  }

  @override
  void didUpdateWidget(covariant ShortVideoPageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.id != widget.video.id) {
      _disposeController();
      _viewSent = widget.video.viewedByMe;
      _watchedSec = 0;
      _init();
    } else if (oldWidget.isActive != widget.isActive) {
      _syncPlayback();
    }
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final cache = ref.read(shortVideoCacheManagerProvider);
      final c = await createShortVideoController(
        url: widget.video.videoUrl,
        cacheManager: cache,
      );
      if (!mounted) {
        await c.dispose();
        return;
      }
      _controller = c;
      setState(() => _loading = false);
      _syncPlayback();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  void _syncPlayback() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    if (widget.isActive) {
      c.play();
      _startViewTracking();
    } else {
      c.pause();
      _stopViewTracking();
    }
  }

  void _startViewTracking() {
    if (_viewSent) return;
    _viewTimer?.cancel();
    _viewTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!widget.isActive) return;
      _watchedSec += 1;
      if (!_viewSent && _watchedSec >= 3) {
        _viewSent = true;
        _sendView();
      }
    });
  }

  void _stopViewTracking() {
    _viewTimer?.cancel();
    _viewTimer = null;
  }

  Future<void> _sendView() async {
    try {
      final res = await ref.read(shortsRepositoryProvider).recordView(
            widget.video.id,
            watchedSec: _watchedSec,
          );
      if (res.counted) {
        widget.onVideoUpdated(
          widget.video.copyWith(
            viewsCount: res.viewsCount,
            viewedByMe: true,
          ),
        );
      }
    } catch (_) {}
  }

  void _disposeController() {
    _stopViewTracking();
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final c = _controller;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_loading)
          _thumbnailOrBlack(video)
        else if (_error || c == null || !c.value.isInitialized)
          _thumbnailOrBlack(video, showError: true)
        else
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: c.value.size.width,
              height: c.value.size.height,
              child: VideoPlayer(c),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [
                Colors.black.withValues(alpha: 0.65),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 78,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
          child: ShortVideoInfoOverlay(video: video),
        ),
        Positioned(
          right: 10,
          bottom: MediaQuery.paddingOf(context).bottom + 40,
          child: ShortVideoActionsRail(
            video: video,
            onVideoUpdated: widget.onVideoUpdated,
          ),
        ),
        if (c != null && c.value.isInitialized)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (c.value.isPlaying) {
                  c.pause();
                } else {
                  c.play();
                }
                setState(() {});
              },
              child: Center(
                child: AnimatedOpacity(
                  opacity: c.value.isPlaying ? 0 : 0.85,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(
                    Icons.play_circle_fill,
                    size: 72,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _thumbnailOrBlack(ShortVideoEntity video, {bool showError = false}) {
    final thumb = video.thumbnailUrl;
    return ColoredBox(
      color: Colors.black,
      child: thumb != null && thumb.isNotEmpty
          ? Image.network(
              thumb,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => _centerMsg(showError),
            )
          : _centerMsg(showError),
    );
  }

  Widget _centerMsg(bool showError) {
    if (showError) {
      return const Center(
        child: Text(
          'Video yüklenemedi',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return const Center(
      child: CircularProgressIndicator(color: Colors.white54),
    );
  }
}
