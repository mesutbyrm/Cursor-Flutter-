import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/performance/list_perf.dart';
import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_providers.dart';
import '../utils/short_video_player_util.dart';
import 'short_video_actions_rail.dart';
import 'short_video_pip_overlay.dart';

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
  var _showHeart = false;

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
      final dio = ref.read(dioProvider);
      final c = await createShortVideoController(
        url: widget.video.videoUrl,
        videoId: widget.video.id,
        dio: dio,
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
        await FirebaseBootstrap.logEvent(
          'short_view',
          parameters: {
            'video_id': widget.video.id,
            'watched_sec': _watchedSec.round(),
          },
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

  Future<void> _doubleTapLike() async {
    setState(() => _showHeart = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeart = false);
    });
    if (widget.video.likedByMe) return;
    try {
      final res = await ref.read(shortsRepositoryProvider).toggleLike(widget.video.id);
      widget.onVideoUpdated(
        widget.video.copyWith(likedByMe: res.liked, likesCount: res.likesCount),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final c = _controller;

    return ListPerf.repaint(
      Stack(
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
          child: ShortVideoInfoOverlay(
            video: video,
            onAuthorTap: () {
              final uid = video.userId.isNotEmpty
                  ? video.userId
                  : (video.author?.id ?? '');
              if (uid.isNotEmpty) context.push('/user/$uid');
            },
            onDuetTap: video.duetOfId != null
                ? () => context.push('/shorts?videoId=${video.duetOfId}')
                : null,
          ),
        ),
        Positioned(
          right: 10,
          bottom: MediaQuery.paddingOf(context).bottom + 40,
          child: ShortVideoActionsRail(
            video: video,
            videoController: c,
            onVideoUpdated: widget.onVideoUpdated,
          ),
        ),
        const ShortVideoPipOverlay(),
        if (c != null && c.value.isInitialized)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: _doubleTapLike,
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
        if (_showHeart)
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1.2),
              duration: const Duration(milliseconds: 400),
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: child,
              ),
              child: Icon(
                Icons.favorite,
                size: 96,
                color: Colors.redAccent.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbnailOrBlack(ShortVideoEntity video, {bool showError = false}) {
    final thumb = video.thumbnailUrl;
    return ColoredBox(
      color: Colors.black,
      child: thumb != null && thumb.isNotEmpty
          ? CanlifalNetworkImage(
              url: thumb,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorWidget: _centerMsg(showError),
              placeholder: _centerMsg(false),
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
