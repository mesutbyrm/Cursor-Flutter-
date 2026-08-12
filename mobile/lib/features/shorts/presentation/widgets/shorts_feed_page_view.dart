import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/short_video_entity.dart';
import '../../domain/entities/shorts_feed_entry.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../providers/shorts_feed_index_provider.dart';
import '../providers/shorts_playback_coordinator.dart';
import '../providers/shorts_playback_providers.dart';
import '../providers/shorts_providers.dart';
import '../providers/shorts_video_pool_provider.dart';
import '../utils/shorts_feed_scroll_physics.dart';
import '../widgets/short_sponsored_tile.dart';
import '../widgets/short_video_page_tile.dart';
import '../widgets/shorts_feed_placeholder_tile.dart';

/// Tek feed öğesi — yalnızca komşu sayfalar rebuild olur.
class ShortsFeedPageItem extends ConsumerWidget {
  const ShortsFeedPageItem({
    super.key,
    required this.index,
    required this.entry,
    required this.tab,
    required this.onVideoUpdated,
    required this.onAdSkip,
  });

  final int index;
  final ShortsFeedEntry entry;
  final ShortsFeedTab tab;
  final ValueChanged<ShortVideoEntity> onVideoUpdated;
  final VoidCallback onAdSkip;

  /// Aktif + önceki + sonraki — yalnızca 3 tam tile.
  static const _videoWindow = 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(shortsFeedIndexProvider);
    final distance = (index - current).abs();

    if (distance > _videoWindow) {
      return ShortsFeedPlaceholderTile(entry: entry);
    }

    if (entry.isAd && entry.ad != null) {
      return RepaintBoundary(
        child: ShortSponsoredTile(
          key: ValueKey(entry.id),
          ad: entry.ad!,
          isActive: index == current,
          onSkip: onAdSkip,
        ),
      );
    }

    final video = entry.video;
    if (video == null) {
      return const ColoredBox(color: Colors.black);
    }

    return RepaintBoundary(
      child: ShortVideoPageTile(
        key: ValueKey(video.id),
        video: video,
        isActive: index == current,
        onVideoUpdated: onVideoUpdated,
      ),
    );
  }
}

/// Dikey PageView — TikTok/Reels kaydırma.
class ShortsFeedPageView extends ConsumerStatefulWidget {
  const ShortsFeedPageView({
    super.key,
    required this.entries,
    required this.tab,
    required this.initialIndex,
    required this.onVideoUpdated,
  });

  final List<ShortsFeedEntry> entries;
  final ShortsFeedTab tab;
  final int initialIndex;
  final ValueChanged<ShortVideoEntity> onVideoUpdated;

  @override
  ConsumerState<ShortsFeedPageView> createState() => _ShortsFeedPageViewState();
}

class _ShortsFeedPageViewState extends ConsumerState<ShortsFeedPageView> {
  late final PageController _pageCtrl;
  var _loadMoreScheduled = false;

  List<ShortVideoEntity> get _videosOnly => widget.entries
      .map((e) => e.video)
      .whereType<ShortVideoEntity>()
      .toList();

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: widget.initialIndex);
    ref.read(shortsFeedIndexProvider.notifier).state = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onIndexChanged(widget.initialIndex, immediate: true);
    });
    _pageCtrl.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ShortsFeedPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries.length != widget.entries.length) {
      final idx = ref.read(shortsFeedIndexProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _warmPool(idx);
        _startPlayback(idx);
      });
    }
  }

  void _onScroll() {
    if (!_pageCtrl.hasClients) return;
    final page = _pageCtrl.page;
    if (page == null) return;
    final target = page.round();
    final current = ref.read(shortsFeedIndexProvider);
    if (target != current && (page - target).abs() < 0.5) {
      _onIndexChanged(target);
    }
  }

  void _onIndexChanged(int index, {bool immediate = false}) {
    ref.read(shortsFeedIndexProvider.notifier).state = index;
    _warmPool(index);
    _maybeLoadMore(index);
    if (immediate) {
      _startPlayback(index);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.read(shortsFeedIndexProvider) == index) {
          _startPlayback(index);
        }
      });
    }
  }

  void _warmPool(int index) {
    final videos = _videosOnly;
    if (videos.isEmpty) return;
    final entry = widget.entries.elementAtOrNull(index);
    final active = entry?.video;
    if (active == null) return;
    final videoIndex = videos.indexWhere((v) => v.id == active.id);
    if (videoIndex < 0) return;
    ref.read(shortsVideoPoolProvider).warm(videos, videoIndex);
  }

  void _startPlayback(int index) {
    final entry = widget.entries.elementAtOrNull(index);
    final video = entry?.video;
    if (video == null) return;

    requestShortsPlayback(ref, video.id);

    final pool = ref.read(shortsVideoPoolProvider);
    final speed = ref.read(shortPlaybackSpeedProvider);
    unawaited(() async {
      try {
        await pool.acquire(video);
        if (!mounted) return;
        if (ref.read(shortsFeedIndexProvider) != index) return;
        pool.setActive(video.id, playbackSpeed: speed);
        requestShortsPlayback(ref, video.id);
      } catch (_) {}
    }());
  }

  void _maybeLoadMore(int index) {
    if (_loadMoreScheduled) return;
    if (index < widget.entries.length - 4) return;
    _loadMoreScheduled = true;
    ref.read(shortsFeedProvider(widget.tab).notifier).loadMore().whenComplete(() {
      _loadMoreScheduled = false;
    });
  }

  void _onPageSettled(int index) => _onIndexChanged(index);

  void _skipAd(int index) {
    if (index + 1 < widget.entries.length) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageCtrl.removeListener(_onScroll);
    unawaited(ref.read(shortsVideoPoolProvider).setActive(null));
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageCtrl,
      scrollDirection: Axis.vertical,
      pageSnapping: true,
      allowImplicitScrolling: true,
      physics: shortsFeedPagePhysics,
      itemCount: widget.entries.length,
      onPageChanged: _onPageSettled,
      itemBuilder: (context, i) {
        return ShortsFeedPageItem(
          index: i,
          entry: widget.entries[i],
          tab: widget.tab,
          onVideoUpdated: widget.onVideoUpdated,
          onAdSkip: () => _skipAd(i),
        );
      },
    );
  }
}

extension _ListElementAtOrNull<E> on List<E> {
  E? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
