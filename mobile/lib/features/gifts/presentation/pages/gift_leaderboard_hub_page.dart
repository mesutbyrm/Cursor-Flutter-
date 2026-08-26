import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../data/leaderboard_remote_datasource.dart';
import '../../domain/gift_leaderboard_entry.dart';
import '../../../../core/network/dio_provider.dart';
import '../widgets/top_gifters_leaderboard.dart';

final leaderboardRemoteProvider = Provider<LeaderboardRemoteDataSource>((ref) {
  return LeaderboardRemoteDataSource(ref.watch(dioProvider));
});

final globalGiftLeaderboardProvider = FutureProvider.autoDispose
    .family<List<GiftLeaderboardEntry>, GiftLeaderboardPeriod>((ref, period) {
  return ref.watch(leaderboardRemoteProvider).fetchGlobalGiftLeaderboard(
        period: period,
      );
});

class GiftLeaderboardHubPage extends ConsumerStatefulWidget {
  const GiftLeaderboardHubPage({super.key});

  @override
  ConsumerState<GiftLeaderboardHubPage> createState() =>
      _GiftLeaderboardHubPageState();
}

class _GiftLeaderboardHubPageState extends ConsumerState<GiftLeaderboardHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: GiftLeaderboardPeriod.values.length - 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final periods = GiftLeaderboardPeriod.values
        .where((p) => p != GiftLeaderboardPeriod.session)
        .toList();

    return DiscoverSubPage(
      title: 'Hediye liderleri',
      subtitle: 'Haftalık ve aylık en çok hediye gönderenler',
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            labelColor: context.accentPink,
            unselectedLabelColor: context.colors.onSurfaceVariant,
            tabs: [for (final p in periods) Tab(text: p.label)],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                for (final period in periods)
                  _PeriodLeaderboard(period: period),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodLeaderboard extends ConsumerWidget {
  const _PeriodLeaderboard({required this.period});

  final GiftLeaderboardPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(globalGiftLeaderboardProvider(period));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ApiException.userMessage(e)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  ref.invalidate(globalGiftLeaderboardProvider(period)),
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Text(
              'Bu dönem için veri yok',
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(globalGiftLeaderboardProvider(period));
            await ref.read(globalGiftLeaderboardProvider(period).future);
          },
          child: TopGiftersLeaderboard(entries: entries),
        );
      },
    );
  }
}
