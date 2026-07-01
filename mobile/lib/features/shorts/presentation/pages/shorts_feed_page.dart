import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/ui/premium_2026/premium_motion.dart';
import '../../domain/entities/short_video_entity.dart';
import '../../domain/entities/shorts_feed_entry.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../providers/shorts_providers.dart';
import '../providers/shorts_playback_providers.dart';
import '../providers/shorts_offline_sync_provider.dart';
import '../providers/shorts_video_pool_provider.dart';
import '../utils/shorts_content_filter.dart';
import '../utils/shorts_feed_entries.dart';
import '../widgets/short_sponsored_tile.dart';
import '../widgets/short_video_page_tile.dart';
import '../widgets/shorts_premium_theme.dart';
import '../widgets/shorts_safe_settings_sheet.dart';

/// TikTok tarzı dikey kısa video akışı — For You / Takip sekmeleri.
class ShortsFeedPage extends ConsumerStatefulWidget {
  const ShortsFeedPage({super.key, this.initialVideoId});

  final String? initialVideoId;

  @override
  ConsumerState<ShortsFeedPage> createState() => _ShortsFeedPageState();
}

class _ShortsFeedPageState extends ConsumerState<ShortsFeedPage> {
  PageController? _pageCtrl;
  var _index = 0;
  final _entries = <ShortsFeedEntry>[];
  var _deepLinkHandled = false;

  @override
  void dispose() {
    _pageCtrl?.dispose();
    super.dispose();
  }

  List<ShortVideoEntity> get _videosOnly =>
      _entries.map((e) => e.video).whereType<ShortVideoEntity>().toList();

  void _ensureController(int count) {
    if (_pageCtrl != null) return;
    var initial = 0;
    if (widget.initialVideoId != null) {
      final i = _entries.indexWhere(
        (e) => e.video?.id == widget.initialVideoId,
      );
      if (i >= 0) initial = i;
    }
    _index = initial;
    _pageCtrl = PageController(initialPage: initial);
  }

  void _warmPool(int index) {
    final videos = _videosOnly;
    if (videos.isEmpty) return;
    final active = _entries[index].video;
    if (active == null) return;
    final videoIndex = videos.indexWhere((v) => v.id == active.id);
    if (videoIndex < 0) return;
    ref.read(shortsVideoPoolProvider).warm(videos, videoIndex);
  }

  void _onPageChanged(int i, ShortsFeedTab tab) {
    setState(() => _index = i);
    _warmPool(i);
    final videos = _videosOnly;
    if (videos.isNotEmpty && i >= _entries.length - 4) {
      ref.read(shortsFeedProvider(tab).notifier).loadMore();
    }
  }

  void _patchVideo(ShortVideoEntity updated, ShortsFeedTab tab) {
    setState(() {
      final idx = _entries.indexWhere((e) => e.video?.id == updated.id);
      if (idx >= 0 && _entries[idx].video != null) {
        _entries[idx] = ShortsFeedEntry.video(updated);
      }
    });
    ref.read(shortsFeedProvider(tab).notifier).patchVideo(updated.id, updated);
  }

  void _onTabChanged(ShortsFeedTab tab) {
    ref.read(shortsFeedTabProvider.notifier).state = tab;
    _pageCtrl?.dispose();
    _pageCtrl = null;
    _entries.clear();
    _index = 0;
    _deepLinkHandled = false;
  }

  Future<void> _handleDeepLink(List<ShortVideoEntity> videos, ShortsFeedTab tab) async {
    final id = widget.initialVideoId;
    if (id == null || id.isEmpty || _deepLinkHandled) return;
    _deepLinkHandled = true;
    if (videos.any((v) => v.id == id)) return;
    await ref.read(shortsFeedProvider(tab).notifier).ensureVideo(id);
  }

  void _rebuildEntries(List<ShortVideoEntity> videos) {
    final built = buildShortsFeedEntries(videos);
    if (_entries.map((e) => e.id).join() != built.map((e) => e.id).join()) {
      _entries
        ..clear()
        ..addAll(built);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(shortsOfflineSyncProvider);
    final tab = ref.watch(shortsFeedTabProvider);
    final feed = ref.watch(shortsFeedProvider(tab));
    final safe = ref.watch(shortsSafeSettingsProvider).valueOrNull ??
        const ShortsSafeSettings(restrictedMode: false, hideMature: true);
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: ShortsPremiumTheme.feedBackground(context),
      body: feed.when(
        loading: () => Stack(
          children: [
            const PremiumShortFeedSkeleton(),
            _topBar(context, top, tab),
          ],
        ),
        error: (e, _) => Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.colors.onSurfaceMuted),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.read(shortsFeedProvider(tab).notifier).refresh(),
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            ),
            _topBar(context, top, tab),
          ],
        ),
        data: (videos) {
          if (videos.isEmpty) {
            return Stack(
              children: [
                Center(
                  child: Text(
                    'Henüz kısa video yok.\nİlk videoyu sen yükle!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.colors.onSurfaceMuted,
                      height: 1.4,
                    ),
                  ),
                ),
                _topBar(context, top, tab),
              ],
            );
          }

          final filtered = filterShortsForSafeSettings(videos, safe);
          if (filtered.isEmpty) {
            return Stack(
              children: [
                Center(
                  child: Text(
                    'Güvenlik filtresi nedeniyle gösterilecek video yok.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.colors.onSurfaceMuted),
                  ),
                ),
                _topBar(context, top, tab),
              ],
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleDeepLink(filtered, tab);
          });

          _rebuildEntries(filtered);

          if (_pageCtrl != null &&
              widget.initialVideoId != null &&
              _entries.any((e) => e.video?.id == widget.initialVideoId)) {
            final i =
                _entries.indexWhere((e) => e.video?.id == widget.initialVideoId);
            if (i >= 0 && i != _index) {
              _pageCtrl!.jumpToPage(i);
              _index = i;
            }
          }

          _ensureController(_entries.length);
          WidgetsBinding.instance.addPostFrameCallback((_) => _warmPool(_index));

          return Stack(
            children: [
              PageView.builder(
                controller: _pageCtrl,
                scrollDirection: Axis.vertical,
                physics: PremiumMotion.pagePhysics,
                itemCount: _entries.length,
                onPageChanged: (i) => _onPageChanged(i, tab),
                itemBuilder: (context, i) {
                  if ((i - _index).abs() > 2) {
                    final entry = _entries[i];
                    if (entry.isVideo && entry.video!.thumbnailUrl != null) {
                      return ColoredBox(
                        color: Colors.black,
                        child: Image.network(
                          entry.video!.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: ShortsPremiumTheme.feedBackground(context),
                          ),
                        ),
                      );
                    }
                    return ColoredBox(
                      color: ShortsPremiumTheme.feedBackground(context),
                    );
                  }
                  final entry = _entries[i];
                  if (entry.isAd && entry.ad != null) {
                    return ShortSponsoredTile(
                      key: ValueKey(entry.id),
                      ad: entry.ad!,
                      isActive: i == _index,
                      onSkip: () {
                        if (_pageCtrl != null && i + 1 < _entries.length) {
                          _pageCtrl!.nextPage(
                            duration: PremiumMotion.fast,
                            curve: PremiumMotion.easeOut,
                          );
                        }
                      },
                    );
                  }
                  final video = entry.video!;
                  return ShortVideoPageTile(
                    key: ValueKey(video.id),
                    video: video,
                    isActive: i == _index,
                    onVideoUpdated: (v) => _patchVideo(v, tab),
                  );
                },
              ),
              _topBar(context, top, tab),
            ],
          );
        },
      ),
    );
  }

  Widget _topBar(BuildContext context, double top, ShortsFeedTab tab) {
    final safe = ref.watch(shortsSafeSettingsProvider).valueOrNull ??
        const ShortsSafeSettings(restrictedMode: false, hideMature: true);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ShortsPremiumTheme.feedTopBar(
        context: context,
        child: Padding(
          padding: EdgeInsets.only(top: top + 4),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push('/shorts/explore'),
                    icon: const Icon(Icons.search_rounded, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () => showShortsSafeSettingsSheet(context, ref),
                    icon: Icon(
                      safe.restrictedMode
                          ? Icons.shield_outlined
                          : Icons.shield_moon_outlined,
                      color: safe.restrictedMode ? Colors.amber : Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/shorts/upload'),
                    icon: const Icon(Icons.video_call_outlined,
                        color: Colors.white),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FeedTabChip(
                    label: 'Sana Özel',
                    selected: tab == ShortsFeedTab.forYou,
                    onTap: () => _onTabChanged(ShortsFeedTab.forYou),
                  ),
                  const SizedBox(width: 20),
                  _FeedTabChip(
                    label: 'Takip',
                    selected: tab == ShortsFeedTab.following,
                    onTap: () => _onTabChanged(ShortsFeedTab.following),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedTabChip extends StatelessWidget {
  const _FeedTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final curve = Theme.of(context).platform == TargetPlatform.iOS
        ? Curves.easeOutCubic
        : PremiumMotion.easeOut;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedDefaultTextStyle(
            duration: PremiumMotion.fast,
            curve: curve,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.55),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 15,
            ),
            child: Text(label),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: PremiumMotion.fast,
            curve: curve,
            width: selected ? 28 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

String shortVideoShareUrl(String videoId) {
  return '${Env.siteOrigin}/shorts?videoId=$videoId';
}
