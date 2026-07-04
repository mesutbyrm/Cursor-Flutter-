import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/gift_insights_remote_datasource.dart';
import '../../domain/gift_leaderboard_entry.dart';

final giftInsightsRemoteProvider = Provider<GiftInsightsRemoteDataSource>((ref) {
  return GiftInsightsRemoteDataSource(ref.watch(dioProvider));
});

/// Liderlik tablosu filtreleri.
class GiftLeaderboardFilter {
  const GiftLeaderboardFilter({
    this.type = 'senders',
    this.period = 'weekly',
    this.scope = 'tr',
    this.context = 'all',
  });

  final String type;
  final String period;
  final String scope;
  final String context;

  GiftLeaderboardFilter copyWith({
    String? type,
    String? period,
    String? scope,
    String? context,
  }) =>
      GiftLeaderboardFilter(
        type: type ?? this.type,
        period: period ?? this.period,
        scope: scope ?? this.scope,
        context: context ?? this.context,
      );

  @override
  bool operator ==(Object other) =>
      other is GiftLeaderboardFilter &&
      other.type == type &&
      other.period == period &&
      other.scope == scope &&
      other.context == context;

  @override
  int get hashCode => Object.hash(type, period, scope, context);
}

/// Seçili filtre (UI state).
final giftLeaderboardFilterProvider =
    StateProvider<GiftLeaderboardFilter>((ref) => const GiftLeaderboardFilter());

/// Filtreye göre liderlik tablosu.
final giftLeaderboardProvider = FutureProvider.autoDispose
    .family<List<GiftLeaderboardEntry>, GiftLeaderboardFilter>((ref, filter) {
  return ref.read(giftInsightsRemoteProvider).fetchLeaderboard(
        type: filter.type,
        period: filter.period,
        scope: filter.scope,
        context: filter.context,
      );
});
