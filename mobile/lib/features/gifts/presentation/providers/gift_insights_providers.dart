import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/gift_insights_remote_datasource.dart';
import '../../domain/gift_collection.dart';
import '../../domain/gift_feed_item.dart';
import '../../domain/gift_leaderboard_entry.dart';
import '../../domain/gift_mission.dart';
import '../../domain/gift_sender_map.dart';
import '../../domain/supporter_badge.dart';

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

/// Kendi destekçi rozetim (userId boş) veya belirli kullanıcının rozeti.
final supporterBadgeProvider = FutureProvider.autoDispose
    .family<SupporterBadge?, String?>((ref, userId) {
  return ref.read(giftInsightsRemoteProvider).fetchBadge(userId: userId);
});

/// Bir kullanıcının hediye koleksiyonu.
final giftCollectionProvider = FutureProvider.autoDispose
    .family<GiftCollection, String>((ref, userId) {
  return ref.read(giftInsightsRemoteProvider).fetchCollection(userId);
});

/// Bir kullanıcının hediye albümü.
final giftAlbumProvider =
    FutureProvider.autoDispose.family<GiftAlbum, String>((ref, userId) {
  return ref.read(giftInsightsRemoteProvider).fetchAlbum(userId);
});

/// Bir bağlamdaki Efsane İlk Destekçi.
typedef FirstGifterKey = ({String context, String contextId});

final firstGifterProvider =
    FutureProvider.autoDispose.family<FirstGifter?, FirstGifterKey>((ref, key) {
  return ref.read(giftInsightsRemoteProvider).fetchFirstGifter(
        context: key.context,
        contextId: key.contextId,
      );
});

/// Canlı hediye akışı. Anahtar boşsa genel akış.
typedef GiftFeedKey = ({String? context, String? contextId});

final giftFeedProvider = FutureProvider.autoDispose
    .family<List<GiftFeedItem>, GiftFeedKey>((ref, key) {
  return ref.read(giftInsightsRemoteProvider).fetchFeed(
        context: key.context,
        contextId: key.contextId,
      );
});

/// Gönderen haritası filtresi (dönem + kapsam).
typedef GiftMapKey = ({String period, String scope});

final giftSenderMapProvider =
    FutureProvider.autoDispose.family<GiftSenderMap, GiftMapKey>((ref, key) {
  return ref
      .read(giftInsightsRemoteProvider)
      .fetchSenderMap(period: key.period, scope: key.scope);
});

/// Bana özel hediye önerileri.
final giftRecommendationsProvider = FutureProvider.autoDispose
    .family<List<GiftRecommendation>, String?>((ref, context) {
  return ref
      .read(giftInsightsRemoteProvider)
      .fetchRecommendations(context: context);
});

/// Günlük görevler (tanım + bugünkü ilerleme birleşik).
final giftMissionsProvider =
    FutureProvider.autoDispose<List<GiftMission>>((ref) {
  return ref.read(giftInsightsRemoteProvider).fetchMissions();
});
