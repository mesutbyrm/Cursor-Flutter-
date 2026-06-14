import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_providers.dart';
import '../utils/short_video_player_util.dart';
import '../widgets/short_video_page_tile.dart';

/// TikTok tarzı dikey kısa video akışı.
class ShortsFeedPage extends ConsumerStatefulWidget {
  const ShortsFeedPage({super.key, this.initialVideoId});

  final String? initialVideoId;

  @override
  ConsumerState<ShortsFeedPage> createState() => _ShortsFeedPageState();
}

class _ShortsFeedPageState extends ConsumerState<ShortsFeedPage> {
  PageController? _pageCtrl;
  var _index = 0;
  final _localVideos = <ShortVideoEntity>[];

  @override
  void dispose() {
    _pageCtrl?.dispose();
    super.dispose();
  }

  void _ensureController(int count) {
    if (_pageCtrl != null) return;
    var initial = 0;
    if (widget.initialVideoId != null) {
      final i = _localVideos.indexWhere((v) => v.id == widget.initialVideoId);
      if (i >= 0) initial = i;
    }
    _index = initial;
    _pageCtrl = PageController(initialPage: initial);
  }

  void _preloadAround(List<ShortVideoEntity> videos, int i) {
    final cache = ref.read(shortVideoCacheManagerProvider);
    for (final offset in [0, 1, 2]) {
      final j = i + offset;
      if (j >= 0 && j < videos.length) {
        preloadShortVideoUrl(videos[j].videoUrl, cache);
      }
    }
  }

  void _onPageChanged(int i, List<ShortVideoEntity> videos) {
    setState(() => _index = i);
    _preloadAround(videos, i);
    if (i >= videos.length - 3) {
      ref.read(shortsFeedProvider.notifier).loadMore();
    }
  }

  void _patchVideo(ShortVideoEntity updated) {
    setState(() {
      final idx = _localVideos.indexWhere((v) => v.id == updated.id);
      if (idx >= 0) _localVideos[idx] = updated;
    });
    ref.read(shortsFeedProvider.notifier).patchVideo(updated.id, updated);
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(shortsFeedProvider);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: feed.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.accentPurple),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.read(shortsFeedProvider.notifier).refresh(),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
        data: (videos) {
          if (videos.isEmpty) {
            return Stack(
              children: [
                const Center(
                  child: Text(
                    'Henüz kısa video yok.\nİlk videoyu sen yükle!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ),
                _topBar(context, top),
              ],
            );
          }

          if (_localVideos.length != videos.length ||
              _localVideos.map((v) => v.id).join() !=
                  videos.map((v) => v.id).join()) {
            _localVideos
              ..clear()
              ..addAll(videos);
          }

          _ensureController(_localVideos.length);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _preloadAround(_localVideos, _index);
          });

          return Stack(
            children: [
              PageView.builder(
                controller: _pageCtrl,
                scrollDirection: Axis.vertical,
                itemCount: _localVideos.length,
                onPageChanged: (i) => _onPageChanged(i, _localVideos),
                itemBuilder: (context, i) {
                  if ((i - _index).abs() > 1) {
                    return const ColoredBox(color: Colors.black);
                  }
                  final video = _localVideos[i];
                  return ShortVideoPageTile(
                    key: ValueKey(video.id),
                    video: video,
                    isActive: i == _index,
                    onVideoUpdated: _patchVideo,
                  );
                },
              ),
              _topBar(context, top),
            ],
          );
        },
      ),
    );
  }

  Widget _topBar(BuildContext context, double top) {
    return Positioned(
      top: top + 8,
      left: 8,
      right: 8,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          const Spacer(),
          Text(
            'Kısa Videolar',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => context.push('/shorts/upload'),
            icon: const Icon(Icons.video_call_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
