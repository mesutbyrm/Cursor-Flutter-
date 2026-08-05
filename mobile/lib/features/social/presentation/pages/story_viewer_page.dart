import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/social_story_ring_entity.dart';
import '../providers/social_providers.dart';

/// Hikâye görüntüleyici — görsel/video, otomatik ilerleme, kendi hikâyesini sil.
class StoryViewerPage extends ConsumerStatefulWidget {
  const StoryViewerPage({
    super.key,
    required this.ring,
    this.initialIndex = 0,
  });

  final SocialStoryRingEntity ring;
  final int initialIndex;

  @override
  ConsumerState<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends ConsumerState<StoryViewerPage> {
  late var _index = widget.initialIndex.clamp(0, _stories.length - 1);
  Timer? _advanceTimer;
  VideoPlayerController? _video;
  var _progress = 0.0;
  var _deleting = false;

  static const _imageDuration = Duration(seconds: 5);

  List<SocialStoryItemEntity> get _stories {
    if (widget.ring.stories.isNotEmpty) return widget.ring.stories;
    final preview = widget.ring.previewUrl;
    if (preview == null || preview.isEmpty) return const [];
    return [SocialStoryItemEntity(id: 'preview', mediaUrl: preview)];
  }

  SocialStoryItemEntity? get _current =>
      _stories.isNotEmpty ? _stories[_index] : null;

  bool get _isVideo {
    final t = (_current?.type ?? '').toLowerCase();
    final url = _current?.mediaUrl.toLowerCase() ?? '';
    return t.contains('video') ||
        url.endsWith('.mp4') ||
        url.endsWith('.webm') ||
        url.contains('/video/');
  }

  bool get _isOwn {
    final me = ref.read(authControllerProvider).valueOrNull;
    return widget.ring.isOwn ||
        (me != null && me.id == widget.ring.user.id);
  }

  @override
  void initState() {
    super.initState();
    unawaited(_prepareCurrent());
  }

  @override
  void dispose() {
    _cancelAdvance();
    _disposeVideo();
    super.dispose();
  }

  void _cancelAdvance() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
    _progress = 0;
  }

  Future<void> _disposeVideo() async {
    final v = _video;
    _video = null;
    if (v != null) {
      await v.dispose();
    }
  }

  Future<void> _prepareCurrent() async {
    _cancelAdvance();
    await _disposeVideo();
    if (!mounted) return;
    final story = _current;
    if (story == null) return;

    if (_isVideo) {
      try {
        final ctrl = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
        _video = ctrl;
        await ctrl.initialize();
        if (!mounted) return;
        ctrl.setLooping(false);
        await ctrl.play();
        ctrl.addListener(_onVideoTick);
        setState(() {});
        return;
      } catch (_) {
        await _disposeVideo();
      }
    }
    _startImageTimer();
  }

  void _onVideoTick() {
    final v = _video;
    if (v == null || !v.value.isInitialized) return;
    final dur = v.value.duration.inMilliseconds;
    if (dur <= 0) return;
    final pos = v.value.position.inMilliseconds;
    if (mounted) {
      setState(() {
        _progress = (pos / dur).clamp(0.0, 1.0);
      });
    }
    if (v.value.position >= v.value.duration) {
      _next();
    }
  }

  void _startImageTimer() {
    const tick = Duration(milliseconds: 50);
    final total = _imageDuration.inMilliseconds;
    var elapsed = 0;
    _advanceTimer = Timer.periodic(tick, (t) {
      elapsed += tick.inMilliseconds;
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _progress = (elapsed / total).clamp(0.0, 1.0));
      if (elapsed >= total) {
        t.cancel();
        _next();
      }
    });
  }

  void _next() {
    final stories = _stories;
    if (stories.isEmpty) return;
    if (_index >= stories.length - 1) {
      context.pop();
      return;
    }
    setState(() {
      _index++;
      _progress = 0;
    });
    unawaited(_prepareCurrent());
  }

  void _previous() {
    if (_index <= 0) return;
    setState(() {
      _index--;
      _progress = 0;
    });
    unawaited(_prepareCurrent());
  }

  Future<void> _deleteCurrent() async {
    final story = _current;
    if (story == null || _deleting) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hikâyeyi sil'),
        content: const Text('Bu hikâye kalıcı olarak silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ref.read(socialRepositoryProvider).deleteStory(story.id);
      ref.invalidate(socialStoryRingsProvider);
      if (!mounted) return;
      if (_stories.length <= 1) {
        context.pop();
        return;
      }
      if (_index >= _stories.length - 1) {
        setState(() => _index = (_index - 1).clamp(0, _stories.length - 2));
      }
      unawaited(_prepareCurrent());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hikâye silindi')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = _stories;
    final story = _current;
    final url = story?.mediaUrl;
    final video = _video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isVideo && video != null && video.value.isInitialized)
            FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: video.value.size.width,
                height: video.value.size.height,
                child: VideoPlayer(video),
              ),
            )
          else if (url != null && url.isNotEmpty)
            CanlifalNetworkImage(
              url: url,
              fit: BoxFit.contain,
              errorWidget: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            )
          else
            Center(
              child: Text(
                '${widget.ring.user.display}\nHikâye önizlemesi yok',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _previous,
                    onLongPressDown: (_) => _cancelAdvance(),
                    onLongPressEnd: (_) => unawaited(_prepareCurrent()),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _next,
                    onLongPressDown: (_) => _cancelAdvance(),
                    onLongPressEnd: (_) => unawaited(_prepareCurrent()),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                if (stories.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Row(
                      children: [
                        for (var i = 0; i < stories.length; i++)
                          Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: i < _index
                                    ? 1
                                    : i == _index
                                        ? _progress.clamp(0.05, 1.0)
                                        : 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.ring.user.display,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_isOwn && story != null && story.id != 'preview')
                      IconButton(
                        onPressed: _deleting ? null : _deleteCurrent,
                        icon: _deleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                    if (stories.length > 1)
                      Text(
                        '${_index + 1}/${stories.length}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    TextButton(
                      onPressed: () {
                        context.pop();
                        context.push('/user/${widget.ring.user.id}');
                      },
                      child: const Text('Profil'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (story?.caption != null && story!.caption!.trim().isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 64,
              child: Text(
                story.caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: Text(
                'canlifal.com hikâyeleri',
                style: TextStyle(
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
