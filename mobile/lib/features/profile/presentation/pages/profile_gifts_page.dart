import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/lazy_paginated_sliver_list.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';

class ProfileGiftsPage extends ConsumerStatefulWidget {
  const ProfileGiftsPage({super.key});

  @override
  ConsumerState<ProfileGiftsPage> createState() => _ProfileGiftsPageState();
}

class _ProfileGiftsPageState extends ConsumerState<ProfileGiftsPage> {
  final _lazyReceived = LazyVisibleListController();
  final _lazySent = LazyVisibleListController();

  @override
  void dispose() {
    _lazyReceived.dispose();
    _lazySent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final received = ref.watch(giftsReceivedSummaryProvider);
    final sent = ref.watch(giftsSentSummaryProvider);
    final stats = ref.watch(profileStatsProvider).valueOrNull;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: DiscoverBackground(
          child: DiscoverSubPage(
            title: 'Hediyelerim',
            subtitle: stats == null
                ? 'Aldığın ve gönderdiğin hediyeler'
                : 'Aldın: ${stats.giftsReceivedCount} · Gönderdin: ${stats.giftsSentCount}',
            onRefresh: () async {
              ref.invalidate(giftsReceivedSummaryProvider);
              ref.invalidate(giftsSentSummaryProvider);
              ref.invalidate(profileStatsProvider);
            },
            body: Column(
              children: [
                TabBar(
                  labelColor: AppThemeColors.accentPink,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: AppThemeColors.accentPink,
                  tabs: const [
                    Tab(text: 'Aldıklarım'),
                    Tab(text: 'Gönderdiklerim'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _GiftsGrid(
                        async: received,
                        emptyMessage: 'Henüz hediye alınmadı.',
                        lazy: _lazyReceived,
                      ),
                      _GiftsGrid(
                        async: sent,
                        emptyMessage: 'Henüz hediye göndermedin.',
                        lazy: _lazySent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftsGrid extends StatefulWidget {
  const _GiftsGrid({
    required this.async,
    required this.emptyMessage,
    required this.lazy,
  });

  final AsyncValue<List<GiftReceivedSummaryEntity>> async;
  final String emptyMessage;
  final LazyVisibleListController lazy;

  @override
  State<_GiftsGrid> createState() => _GiftsGridState();
}

class _GiftsGridState extends State<_GiftsGrid> {
  @override
  Widget build(BuildContext context) {
    final async = widget.async;
    return async.when(
      loading: () => const Center(child: DiscoverAccentLoader()),
      error: (e, _) => DiscoverEmptyState(
        icon: Icons.error_outline_rounded,
        message: ApiException.userMessage(e),
      ),
      data: (items) {
        if (items.isEmpty) {
          return DiscoverEmptyState(
            icon: Icons.card_giftcard_outlined,
            message: widget.emptyMessage,
          );
        }
        widget.lazy.reset(items.length);
        final visible = widget.lazy.visibleCount.clamp(0, items.length);
        final hasMore = widget.lazy.hasMore;
        return LayoutBuilder(
          builder: (context, constraints) {
            const crossAxisCount = 3;
            const spacing = 12.0;
            const aspect = 0.85;
            const horizontalPad = 40.0;
            final gridHeight = ListPerf.nestedGridHeight(
              itemCount: visible,
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: aspect,
              crossAxisExtent: constraints.maxWidth - horizontalPad,
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: gridHeight,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        childAspectRatio: aspect,
                      ),
                      itemCount: visible,
                      itemBuilder: (context, i) {
                        final g = items[i];
                        final isUrl = g.icon.startsWith('http');
                        return ListPerf.repaint(
                          ProfileGlass(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isUrl)
                                  CanlifalNetworkImage(
                                    url: g.icon,
                                    height: 36,
                                    errorWidget: Text(g.name, maxLines: 1),
                                  )
                                else
                                  Text(g.icon,
                                      style: const TextStyle(fontSize: 32)),
                                const SizedBox(height: 6),
                                Text(
                                  g.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'x${g.count}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AppThemeColors.accentPink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (hasMore)
                    TextButton(
                      onPressed: () {
                        widget.lazy.loadMore();
                        setState(() {});
                      },
                      child: const Text('Daha fazla hediye göster'),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
