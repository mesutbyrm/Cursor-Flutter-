import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/lucky_gift_remote_datasource.dart';
import '../../domain/lucky_gift_entities.dart';

final luckyGiftRemoteProvider = Provider<LuckyGiftRemoteDataSource>((ref) {
  return LuckyGiftRemoteDataSource(ref.watch(dioProvider));
});

final luckyGiftConfigProvider = FutureProvider.autoDispose<LuckyGiftConfig>((ref) async {
  return ref.watch(luckyGiftRemoteProvider).fetchConfig();
});

final luckyGiftGlobalFeedProvider =
    FutureProvider.autoDispose<List<LuckyGiftHistoryEntry>>((ref) async {
  final result = await ref.watch(luckyGiftRemoteProvider).fetchHistory(
        scope: 'global',
        limit: 20,
      );
  return result.items;
});

final luckyGiftMyHistoryProvider = FutureProvider.autoDispose<
    ({LuckyGiftHistorySummary? summary, List<LuckyGiftHistoryEntry> items})>(
  (ref) async {
    return ref.watch(luckyGiftRemoteProvider).fetchHistory(scope: 'me', limit: 50);
  },
);
