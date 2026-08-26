import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/gift_repository.dart';
import '../../data/gift_sound_pool.dart';
import '../../data/gift_sound_service.dart';
import '../../domain/gift_playable_filter.dart';
import '../../domain/gift_entity.dart';
import '../../domain/gift_leaderboard_entry.dart';
import '../../domain/gift_platform.dart';
import '../../domain/gift_reciprocal.dart';
import '../../../live/domain/entities/live_gift_type.dart';

final giftRepositoryProvider = Provider<GiftRepository>((ref) {
  return GiftRepository(ref.watch(dioProvider));
});

final giftSoundPoolProvider = Provider<GiftSoundPool>((ref) {
  final pool = GiftSoundPool();
  ref.onDispose(pool.dispose);
  return pool;
});

final giftSoundServiceProvider = Provider<GiftSoundService>((ref) {
  final svc = GiftSoundService(ref.watch(giftSoundPoolProvider));
  return svc;
});

/// Mobil katalog — CMS birincil (`/api/gifts/catalog`), oturum boyunca cache.
final liveGiftCatalogProvider = FutureProvider<List<GiftEntity>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(giftRepositoryProvider);
  final catalog = await repo.fetchCatalog(platform: GiftPlatform.mobile);
  return GiftPlayableFilter.forContext(catalog, context: 'all');
});

/// Sesli oda hediye listesi — CMS katalog (admin panelinden eklenen hediyeler dahil).
final voiceRoomGiftCatalogProvider = FutureProvider<List<GiftEntity>>((
  ref,
) async {
  ref.keepAlive();
  final repo = ref.watch(giftRepositoryProvider);
  final general = await ref.watch(liveGiftCatalogProvider.future);
  final voice = await repo.fetchCatalog(
    platform: GiftPlatform.mobile,
    context: 'voice_room',
  );
  return GiftPlayableFilter.mergeContexts(
    voice,
    general,
    context: 'voice_room',
  );
});

/// Canlı yayın hediye listesi.
final liveStreamGiftCatalogProvider = FutureProvider<List<GiftEntity>>((
  ref,
) async {
  ref.keepAlive();
  final repo = ref.watch(giftRepositoryProvider);
  final general = await ref.watch(liveGiftCatalogProvider.future);
  final live = await repo.fetchCatalog(
    platform: GiftPlatform.mobile,
    context: 'live_stream',
  );
  return GiftPlayableFilter.mergeContexts(
    live,
    general,
    context: 'live_stream',
  );
});

final liveGiftTypesLegacyProvider =
    FutureProvider.autoDispose<List<LiveVideoGiftType>>((ref) async {
      final catalog = await ref.watch(liveGiftCatalogProvider.future);
      return catalog.map(LiveVideoGiftType.fromGift).toList();
    });

final streamGiftLeaderboardProvider = FutureProvider.autoDispose
    .family<List<GiftLeaderboardEntry>, String>((ref, streamId) async {
      if (streamId.isEmpty) return const [];
      try {
        return ref.watch(giftRepositoryProvider).fetchLeaderboard(streamId);
      } catch (_) {
        return const [];
      }
    });

final reciprocalGiftHintProvider = FutureProvider.autoDispose
    .family<ReciprocalGiftHint?, String>((ref, userId) async {
      if (userId.trim().isEmpty) return null;
      try {
        final map = await ref
            .watch(giftRepositoryProvider)
            .checkReciprocal(userId);
        final hint = parseReciprocalGiftHint(map);
        return hint.show ? hint : null;
      } catch (_) {
        return null;
      }
    });
