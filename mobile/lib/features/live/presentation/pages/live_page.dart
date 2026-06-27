import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/messages_notifications_actions.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
import '../providers/live_streams_list_notifier.dart';
import '../utils/open_live_stream.dart';
import '../widgets/live_discover_category_chips.dart';
import '../widgets/live_stream_list_tile.dart';

class LivePage extends ConsumerStatefulWidget {
  const LivePage({super.key});

  @override
  ConsumerState<LivePage> createState() => _LivePageState();
}

class _LivePageState extends ConsumerState<LivePage> {
  final _liveScroll = ScrollController();
  Timer? _listRefresh;

  @override
  void initState() {
    super.initState();
    _liveScroll.addListener(_onLiveScroll);
    _listRefresh = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      ref.read(liveStreamsListNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _listRefresh?.cancel();
    _liveScroll.removeListener(_onLiveScroll);
    _liveScroll.dispose();
    super.dispose();
  }

  void _onLiveScroll() {
    if (!_liveScroll.hasClients) return;
    final pos = _liveScroll.position;
    if (pos.pixels >= pos.maxScrollExtent - ListPerf.preloadThresholdPx) {
      ref.read(liveStreamsListNotifierProvider.notifier).loadMore();
    }
  }

  void _refresh() {
    ref.read(liveStreamsListNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: top + 8),
            DiscoverTabHeader(
              title: 'Canlı',
              subtitle: 'Canlı video yayınları',
              actions: [
                const MessagesNotificationsActions(spacing: 4),
                DiscoverIconButton(
                  icon: Icons.videocam_rounded,
                  tooltip: 'Yayına başla',
                  onPressed: () => context.push('/live/type'),
                ),
                DiscoverIconButton(
                  icon: Icons.refresh_rounded,
                  onPressed: _refresh,
                ),
              ],
            ),
            Expanded(
              child: _LiveStreamsTab(scrollController: _liveScroll),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveStreamsTab extends ConsumerWidget {
  const _LiveStreamsTab({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamsListNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: LiveStreamsBranchQuickActions(),
        ),
        const SizedBox(height: 8),
        const LiveDiscoverCategoryChips(),
        const SizedBox(height: 8),
        Expanded(
          child: live.when(
            loading: () => ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, _) => const RepaintBoundary(
                child: PremiumLiveCardSkeleton(),
              ),
            ),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.live_tv_outlined,
              message: ApiException.userMessage(e),
              actionLabel: 'Yenile',
              action: () =>
                  ref.read(liveStreamsListNotifierProvider.notifier).refresh(),
            ),
            data: (streams) {
              if (streams.isEmpty) {
                return const DiscoverEmptyState(
                  icon: Icons.videocam_off_outlined,
                  message:
                      'Şu an canlı yayın yok.\nYeni yayınlar burada görünecek.',
                );
              }
              final hasMore = ref
                  .read(liveStreamsListNotifierProvider.notifier)
                  .hasMore;
              final extra = hasMore ? 1 : 0;
              return ListView.separated(
                cacheExtent: ListPerf.cacheExtent,
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                physics: ListPerf.listPhysics,
                itemCount: streams.length + extra,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  if (i >= streams.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final s = streams[i];
                  return ListPerf.repaint(
                    LiveStreamListTile(
                      stream: s,
                      onTap: s.isLive
                          ? () => openLiveStreamNative(context, ref, s)
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
