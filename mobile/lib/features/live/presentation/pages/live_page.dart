import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../../core/widgets/messages_notifications_actions.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../shell/presentation/widgets/branch_quick_actions.dart';
import '../../../voice_hub/presentation/voice_rooms_body.dart';
import '../providers/live_streams_list_notifier.dart';
import '../providers/live_providers.dart';
import '../utils/open_live_stream.dart';
import '../widgets/live_stream_list_tile.dart';

class LivePage extends ConsumerStatefulWidget {
  const LivePage({super.key});

  @override
  ConsumerState<LivePage> createState() => _LivePageState();
}

class _LivePageState extends ConsumerState<LivePage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _liveScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _liveScroll.addListener(_onLiveScroll);
  }

  @override
  void dispose() {
    _liveScroll.removeListener(_onLiveScroll);
    _liveScroll.dispose();
    _tab.dispose();
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
    ref.invalidate(voiceRoomsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DiscoverBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: top + 8),
            DiscoverTabHeader(
              title: 'Canlı',
              subtitle: 'Yayınlar ve sesli sohbet odaları',
              actions: [
                const MessagesNotificationsActions(spacing: 4),
                DiscoverIconButton(
                  icon: Icons.videocam_rounded,
                  tooltip: 'Yayına başla',
                  onPressed: () => context.push('/live/prep'),
                ),
                DiscoverIconButton(
                  icon: Icons.refresh_rounded,
                  onPressed: _refresh,
                ),
              ],
            ),
            DiscoverSegmentedTabs(
              controller: _tab,
              tabs: const [
                (label: 'Yayınlar', icon: Icons.live_tv_rounded),
                (label: 'Sohbet', icon: Icons.headset_mic_rounded),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _LiveStreamsTab(scrollController: _liveScroll),
                  const _VoiceTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceTab extends StatelessWidget {
  const _VoiceTab();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: LiveVoiceBranchQuickActions(),
        ),
        Expanded(
          child: VoiceRoomsBody(embeddedInLiveShellTab: true),
        ),
      ],
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
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                physics: ListPerf.listPhysics,
                cacheExtent: ListPerf.cacheExtent,
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
