import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/performance/list_perf.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/pro_glass/pro_glass.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/broadcast_history_notifier.dart';

class ProfileBroadcastHistoryPage extends ConsumerStatefulWidget {
  const ProfileBroadcastHistoryPage({super.key});

  @override
  ConsumerState<ProfileBroadcastHistoryPage> createState() =>
      _ProfileBroadcastHistoryPageState();
}

class _ProfileBroadcastHistoryPageState
    extends ConsumerState<ProfileBroadcastHistoryPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - ListPerf.preloadThresholdPx) {
      ref.read(broadcastHistoryNotifierProvider.notifier).loadMore();
    }
  }

  Future<void> _refresh() async {
    await ref.read(broadcastHistoryNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(broadcastHistoryNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'Yayın Geçmişi',
          subtitle: 'Tamamlanan canlı yayınlar',
          onRefresh: _refresh,
          body: history.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => DiscoverEmptyState(
              icon: Icons.error_outline_rounded,
              message: ApiException.userMessage(e),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const DiscoverEmptyState(
                  icon: Icons.history_rounded,
                  message: 'Henüz yayın geçmişi yok.',
                );
              }
              final hasMore =
                  ref.read(broadcastHistoryNotifierProvider.notifier).hasMore;
              return ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                physics: ListPerf.listPhysics,
                itemCount: items.length + (hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  if (i >= items.length) {
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
                  final item = items[i];
                  final when = item.startedAt != null
                      ? DateFormat('d MMM yyyy · HH:mm', 'tr').format(
                          DateTime.tryParse(item.startedAt!) ?? DateTime.now(),
                        )
                      : '';
                  return ProGlassListTile(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.live_tv_rounded,
                          color: AppColors.accentPink,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                when,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                              Text(
                                '${item.giftCount} hediye · ${item.coinsEarned} jeton',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
