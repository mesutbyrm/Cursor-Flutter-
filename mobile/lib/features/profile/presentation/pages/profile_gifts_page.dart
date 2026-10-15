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
            const aspect = 0.72;
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
                        final isImg = g.icon.startsWith('http') ||
                            g.icon.startsWith('/');
                        return ListPerf.repaint(
                          ProfileGlass(
                            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Büyük hediye görseli (önceden 36 px).
                                    SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: isImg
                                          ? CanlifalNetworkImage(
                                              url: g.icon,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.contain,
                                              errorWidget: const Center(
                                                child: Text('🎁',
                                                    style:
                                                        TextStyle(fontSize: 40)),
                                              ),
                                            )
                                          : Center(
                                              child: Text(
                                                g.icon.length <= 4
                                                    ? g.icon
                                                    : '🎁',
                                                style: const TextStyle(
                                                    fontSize: 44),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      g.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${g.count} adet',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppThemeColors.coinGold,
                                      ),
                                    ),
                                  ],
                                ),
                                // Adet rozeti — aynı hediyeden kaç tane.
                                Positioned(
                                  top: -4,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppThemeColors.accentPink,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '×${g.count}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
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
