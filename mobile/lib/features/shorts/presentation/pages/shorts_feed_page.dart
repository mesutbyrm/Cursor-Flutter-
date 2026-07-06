import 'dart:async';

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
import '../providers/shorts_feed_index_provider.dart';
import '../providers/shorts_offline_sync_provider.dart';
import '../providers/shorts_playback_coordinator.dart';
import '../providers/shorts_playback_providers.dart';
import '../providers/shorts_providers.dart';
import '../providers/shorts_video_pool_provider.dart';
import '../utils/shorts_content_filter.dart';
import '../utils/shorts_feed_entries.dart';
import '../widgets/shorts_feed_page_view.dart';
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
  final _entries = <ShortsFeedEntry>[];
  var _deepLinkHandled = false;
  var _initialIndex = 0;
  Key _feedKey = UniqueKey();

  void _patchVideo(ShortVideoEntity updated, ShortsFeedTab tab) {
    final idx = _entries.indexWhere((e) => e.video?.id == updated.id);
    if (idx >= 0 && _entries[idx].video != null) {
      setState(() {
        _entries[idx] = ShortsFeedEntry.video(updated);
      });
    }
    ref.read(shortsFeedProvider(tab).notifier).patchVideo(updated.id, updated);
  }

  void _onTabChanged(ShortsFeedTab tab) {
    ref.read(shortsFeedTabProvider.notifier).state = tab;
    ref.invalidate(shortsFeedIndexProvider);
    ref.invalidate(shortsActiveVideoIdProvider);
    ref.invalidate(shortsPlaybackTickProvider);
    setState(() {
      _entries.clear();
      _deepLinkHandled = false;
      _initialIndex = 0;
      _feedKey = UniqueKey();
    });
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
    final prevSig = _entries.map((e) => e.id).join();
    final nextSig = built.map((e) => e.id).join();
    if (prevSig != nextSig) {
      _entries
        ..clear()
        ..addAll(built);
      if (widget.initialVideoId != null) {
        final i = _entries.indexWhere(
          (e) => e.video?.id == widget.initialVideoId,
        );
        if (i >= 0) _initialIndex = i;
      }
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
            _ShortsFeedTopBar(
              top: top,
              tab: tab,
              onTabChanged: _onTabChanged,
            ),
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
            _ShortsFeedTopBar(
              top: top,
              tab: tab,
              onTabChanged: _onTabChanged,
            ),
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
                _ShortsFeedTopBar(
                  top: top,
                  tab: tab,
                  onTabChanged: _onTabChanged,
                ),
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
                _ShortsFeedTopBar(
                  top: top,
                  tab: tab,
                  onTabChanged: _onTabChanged,
                ),
              ],
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleDeepLink(filtered, tab);
            if (filtered.isNotEmpty) {
              unawaited(ref.read(shortsVideoPoolProvider).warm(filtered, 0));
            }
          });

          _rebuildEntries(filtered);

          return Stack(
            children: [
              ShortsFeedPageView(
                key: _feedKey,
                entries: List.unmodifiable(_entries),
                tab: tab,
                initialIndex: _initialIndex,
                onVideoUpdated: (v) => _patchVideo(v, tab),
              ),
              _ShortsFeedTopBar(
                top: top,
                tab: tab,
                onTabChanged: _onTabChanged,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ShortsFeedTopBar extends ConsumerWidget {
  const _ShortsFeedTopBar({
    required this.top,
    required this.tab,
    required this.onTabChanged,
  });

  final double top;
  final ShortsFeedTab tab;
  final ValueChanged<ShortsFeedTab> onTabChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    onTap: () => onTabChanged(ShortsFeedTab.forYou),
                  ),
                  const SizedBox(width: 20),
                  _FeedTabChip(
                    label: 'Takip',
                    selected: tab == ShortsFeedTab.following,
                    onTap: () => onTabChanged(ShortsFeedTab.following),
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
