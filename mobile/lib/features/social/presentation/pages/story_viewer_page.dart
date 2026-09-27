import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/images/canlifal_image_cache_manager.dart';
import '../../../../core/images/canlifal_image_urls.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/social_story_ring_entity.dart';
import '../providers/social_providers.dart';
import '../providers/story_seen_provider.dart';
import '../utils/social_user_profile_route.dart';

/// Hikâye görüntüleyici — görsel/video, otomatik ilerleme, basılı tut → duraklat,
/// kişiden kişiye geçiş, aşağı kaydır → kapat, kendi hikâyesini sil.
class StoryViewerPage extends ConsumerStatefulWidget {
  const StoryViewerPage({
    super.key,
    required this.ring,
    this.initialIndex = 0,
    this.rings = const [],
  });

  final SocialStoryRingEntity ring;
  final int initialIndex;

  /// Şerit sırası; boşsa yalnızca [ring] gösterilir.
  final List<SocialStoryRingEntity> rings;

  @override
  ConsumerState<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends ConsumerState<StoryViewerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _defaultImageDuration = Duration(seconds: 5);

  late final List<SocialStoryRingEntity> _rings;
  late int _ringIndex;
  late List<SocialStoryItemEntity> _stories;
  late int _index;

  /// Tek ilerleme kaynağı: yalnızca ilerleme çubuğunu yeniden çizer.
  late final AnimationController _progress;
  VideoPlayerController? _video;

  /// Hızlı dokunuşlarda eski yüklemenin yeni hikâyeyi bozmasını engeller.
  var _loadToken = 0;
  var _mediaReady = false;
  var _mediaError = false;
  var _held = false;
  var _deleting = false;
  var _closing = false;
  var _dragDy = 0.0;

  SocialStoryRingEntity get _ring => _rings[_ringIndex];

  SocialStoryItemEntity? get _current =>
      _stories.isNotEmpty ? _stories[_index] : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final start = widget.rings.indexWhere(
      (r) => r.user.id == widget.ring.user.id,
    );
    if (start >= 0) {
      _rings = List.of(widget.rings);
      _rings[start] = widget.ring;
      _ringIndex = start;
    } else {
      _rings = [widget.ring];
      _ringIndex = 0;
    }
    _stories = _storiesOf(_ring);
    _index = _stories.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _stories.length - 1);
    _progress = AnimationController(vsync: this)
      ..addStatusListener((status) {
        // Video oynarken ilerlemeyi oynatıcı sürer; bitişi [_onVideoTick] yakalar.
        if (status == AnimationStatus.completed && _video == null) _next();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareCurrent());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loadToken++;
    _progress.dispose();
    _releaseVideo();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_held) _play();
    } else {
      _pause();
    }
  }

  static List<SocialStoryItemEntity> _storiesOf(SocialStoryRingEntity ring) {
    if (ring.stories.isNotEmpty) return List.of(ring.stories);
    final preview = ring.previewUrl;
    if (preview == null || preview.isEmpty) return [];
    return [SocialStoryItemEntity(id: 'preview', mediaUrl: preview)];
  }

  bool get _isVideo {
    final story = _current;
    if (story == null) return false;
    final t = story.type.toLowerCase();
    final url = story.mediaUrl.toLowerCase();
    return t.contains('video') ||
        url.endsWith('.mp4') ||
        url.endsWith('.webm') ||
        url.contains('/video/');
  }

  bool get _isOwn {
    final me = ref.read(authControllerProvider).valueOrNull;
    return _ring.isOwn || (me != null && me.id == _ring.user.id);
  }

  void _releaseVideo() {
    final v = _video;
    _video = null;
    if (v == null) return;
    v.removeListener(_onVideoTick);
    unawaited(v.dispose());
  }

  Future<void> _prepareCurrent() async {
    final token = ++_loadToken;
    _progress
      ..stop()
      ..value = 0;
    _releaseVideo();
    if (!mounted) return;
    setState(() {
      _mediaReady = false;
      _mediaError = false;
    });
    final story = _current;
    if (story == null) return;

    if (!_isVideo) return; // Görsel: yüklenince [_onImageReady] başlatır.

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl));
    try {
      await ctrl.initialize();
    } catch (_) {
      unawaited(ctrl.dispose());
      if (!mounted || token != _loadToken) return;
      setState(() => _mediaError = true);
      _markSeen(story);
      _startTimed(_defaultImageDuration);
      return;
    }
    if (!mounted || token != _loadToken) {
      unawaited(ctrl.dispose());
      return;
    }
    _video = ctrl;
    ctrl
      ..setLooping(false)
      ..addListener(_onVideoTick);
    setState(() => _mediaReady = true);
    _markSeen(story);
    if (!_held) unawaited(ctrl.play());
  }

  void _onImageReady(int token) {
    if (token != _loadToken || _mediaReady || !mounted) return;
    setState(() => _mediaReady = true);
    final story = _current;
    if (story != null) _markSeen(story);
    _startTimed(_durationOf(story));
  }

  void _onImageFailed(int token) {
    if (token != _loadToken || _mediaError || !mounted) return;
    setState(() => _mediaError = true);
    final story = _current;
    if (story != null) _markSeen(story);
    _startTimed(_durationOf(story));
  }

  static Duration _durationOf(SocialStoryItemEntity? story) {
    final ms = story?.durationMs;
    return ms != null && ms > 0
        ? Duration(milliseconds: ms)
        : _defaultImageDuration;
  }

  void _startTimed(Duration duration) {
    _progress.duration = duration;
    if (!_held) _progress.forward(from: 0);
  }

  void _onVideoTick() {
    final v = _video;
    if (v == null || !v.value.isInitialized) return;
    final dur = v.value.duration.inMilliseconds;
    if (dur <= 0) return;
    _progress.value = (v.value.position.inMilliseconds / dur).clamp(0.0, 1.0);
    if (!v.value.isPlaying && v.value.position >= v.value.duration) {
      v.removeListener(_onVideoTick);
      _next();
    }
  }

  void _markSeen(SocialStoryItemEntity story) {
    if (story.id == 'preview') return;
    ref.read(storySeenProvider.notifier).markSeen(story.id);
  }

  void _pause() {
    _progress.stop();
    _video?.pause();
  }

  void _play() {
    if (!_mediaReady && !_mediaError) return;
    final v = _video;
    if (v != null && v.value.isInitialized) {
      unawaited(v.play());
    } else if (_progress.duration != null && !_progress.isCompleted) {
      _progress.forward();
    }
  }

  void _setHeld(bool held) {
    if (_held == held) return;
    setState(() => _held = held);
    held ? _pause() : _play();
  }

  void _next() {
    if (!mounted || _closing) return;
    if (_index < _stories.length - 1) {
      setState(() => _index++);
      unawaited(_prepareCurrent());
      return;
    }
    if (_ringIndex < _rings.length - 1) {
      _switchRing(_ringIndex + 1);
      return;
    }
    _close();
  }

  void _previous() {
    if (!mounted || _closing) return;
    if (_index > 0) {
      setState(() => _index--);
      unawaited(_prepareCurrent());
      return;
    }
    if (_ringIndex > 0) {
      _switchRing(_ringIndex - 1, fromEnd: true);
      return;
    }
    unawaited(_prepareCurrent()); // İlk hikâyede geri → baştan oynat.
  }

  void _switchRing(int target, {bool fromEnd = false}) {
    final stories = _storiesOf(_rings[target]);
    setState(() {
      _ringIndex = target;
      _stories = stories;
      _index = fromEnd && stories.isNotEmpty ? stories.length - 1 : 0;
    });
    HapticFeedback.selectionClick();
    unawaited(_prepareCurrent());
  }

  void _close() {
    if (_closing) return;
    _closing = true;
    _loadToken++;
    _pause();
    if (context.canPop()) context.pop();
  }

  void _openProfile() {
    final id = _ring.user.id;
    _close();
    if (id.isNotEmpty) context.push(buildSocialUserProfileRoute(id));
  }

  Future<void> _deleteCurrent() async {
    final story = _current;
    if (story == null || _deleting || story.id == 'preview') return;
    _pause();
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
    if (!mounted) return;
    if (ok != true) {
      _play();
      return;
    }
    setState(() => _deleting = true);
    try {
      await ref.read(socialRepositoryProvider).deleteStory(story.id);
      ref.invalidate(socialStoryRingsProvider);
      if (!mounted) return;
      final updated = List<SocialStoryItemEntity>.from(_stories)
        ..removeAt(_index);
      if (updated.isEmpty) {
        _close();
        return;
      }
      setState(() {
        _stories = updated;
        if (_index >= _stories.length) _index = _stories.length - 1;
      });
      unawaited(_prepareCurrent());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hikâye silindi')));
    } catch (e) {
      if (!mounted) return;
      _play();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiException.userMessage(e))));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    final next = (_dragDy + d.delta.dy).clamp(0.0, double.infinity);
    if (next > 0 && _dragDy == 0) _pause();
    setState(() => _dragDy = next);
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    if (_dragDy > 120 || (d.primaryVelocity ?? 0) > 700) {
      _close();
      return;
    }
    setState(() => _dragDy = 0);
    if (!_held) _play();
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -300 && _ringIndex < _rings.length - 1) {
      _switchRing(_ringIndex + 1);
    } else if (v > 300 && _ringIndex > 0) {
      _switchRing(_ringIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final story = _current;
    final size = MediaQuery.sizeOf(context);
    final dismiss = (_dragDy / size.height).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 1 - dismiss * 0.8),
        body: Transform.translate(
          offset: Offset(0, _dragDy),
          child: Transform.scale(
            scale: 1 - dismiss * 0.12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(dismiss > 0 ? 20 : 0),
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey('${_ring.user.id}#$_index#${story?.id}'),
                        child: _buildMedia(story),
                      ),
                    ),
                    if (!_mediaReady && !_mediaError && story != null)
                      const Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    const _Scrim(top: true),
                    const _Scrim(top: false),
                    _GestureLayer(
                      onPrevious: _previous,
                      onNext: _next,
                      onHold: _setHeld,
                      onVerticalDragUpdate: _onVerticalDragUpdate,
                      onVerticalDragEnd: _onVerticalDragEnd,
                      onHorizontalDragEnd: _onHorizontalDragEnd,
                    ),
                    AnimatedOpacity(
                      opacity: _held ? 0 : 1,
                      duration: const Duration(milliseconds: 160),
                      child: _buildChrome(story),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(SocialStoryItemEntity? story) {
    if (story == null) {
      return Center(
        child: Text(
          '${_ring.user.display}\nHikâye önizlemesi yok',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    final video = _video;
    if (_isVideo) {
      if (video != null && video.value.isInitialized) {
        return Center(
          child: AspectRatio(
            aspectRatio: video.value.aspectRatio,
            child: VideoPlayer(video),
          ),
        );
      }
      return const SizedBox.expand();
    }
    // Solan eski görselin geri çağrısı yeni hikâyeyi başlatmasın.
    final token = _loadToken;
    final uri = Uri.tryParse(story.mediaUrl.trim());
    if (uri == null || !uri.hasScheme) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _onImageFailed(token),
      );
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.white54,
          size: 64,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: CanlifalImageUrls.full(story.mediaUrl),
      cacheManager: CanlifalImageCacheManager.instance,
      fadeInDuration: const Duration(milliseconds: 180),
      imageBuilder: (context, provider) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _onImageReady(token),
        );
        return Image(image: provider, fit: BoxFit.contain);
      },
      placeholder: (_, _) => const SizedBox.expand(),
      errorWidget: (_, _, _) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _onImageFailed(token),
        );
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white54,
            size: 64,
          ),
        );
      },
    );
  }

  Widget _buildChrome(SocialStoryItemEntity? story) {
    final created = story?.createdAt;
    final caption = story?.caption?.trim();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: _ProgressBars(
              count: _stories.isEmpty ? 1 : _stories.length,
              index: _index,
              progress: _progress,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: '${_ring.user.display} profilini aç',
                    onTap: _openProfile,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: _openProfile,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          UserAvatar(url: _ring.user.avatarUrl, radius: 16),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _ring.user.display,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (created != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              storyTimeAgo(created, DateTime.now()),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isOwn && story != null && story.id != 'preview')
                  IconButton(
                    tooltip: 'Hikâyeyi sil',
                    onPressed: _deleting ? null : _deleteCurrent,
                    icon: _deleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                          ),
                  ),
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: _close,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          if (_mediaError)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Medya yüklenemedi — süre dolunca devam edilecek',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Spacer(),
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 8)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "az önce", "5 dk", "3 sa", "2 gün".
String storyTimeAgo(DateTime created, DateTime now) {
  final d = now.difference(created);
  if (d.inMinutes < 1) return 'az önce';
  if (d.inHours < 1) return '${d.inMinutes} dk';
  if (d.inDays < 1) return '${d.inHours} sa';
  return '${d.inDays} gün';
}

class _ProgressBars extends StatelessWidget {
  const _ProgressBars({
    required this.count,
    required this.index,
    required this.progress,
  });

  final int count;
  final int index;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hikâye ${index + 1} / $count',
      child: RepaintBoundary(
        child: Row(
          children: [
            for (var i = 0; i < count; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 2.5,
                      child: i == index
                          ? AnimatedBuilder(
                              animation: progress,
                              builder: (_, _) => _bar(progress.value),
                            )
                          : _bar(i < index ? 1 : 0),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static Widget _bar(double value) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Colors.white.withValues(alpha: 0.3)),
        FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: const ColoredBox(color: Colors.white),
        ),
      ],
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.top});

  final bool top;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
      child: IgnorePointer(
        child: Container(
          height: top ? 140 : 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sol üçte bir → geri, kalan → ileri; basılı tut → duraklat.
class _GestureLayer extends StatelessWidget {
  const _GestureLayer({
    required this.onPrevious,
    required this.onNext,
    required this.onHold,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onHorizontalDragEnd,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<bool> onHold;
  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final GestureDragEndCallback onHorizontalDragEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) =>
              d.localPosition.dx < c.maxWidth / 3 ? onPrevious() : onNext(),
          onLongPressStart: (_) => onHold(true),
          onLongPressEnd: (_) => onHold(false),
          onLongPressCancel: () => onHold(false),
          onVerticalDragUpdate: onVerticalDragUpdate,
          onVerticalDragEnd: onVerticalDragEnd,
          onHorizontalDragEnd: onHorizontalDragEnd,
          child: Semantics(
            label: 'Hikâye. Sonraki için dokun, duraklatmak için basılı tut.',
            onTap: onNext,
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }
}
