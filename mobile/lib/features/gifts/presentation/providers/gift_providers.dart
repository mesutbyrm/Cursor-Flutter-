import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/gift_repository.dart';
import '../../data/gift_sound_service.dart';
import '../../domain/gift_entity.dart';
import '../../domain/gift_leaderboard_entry.dart';
import '../../domain/gift_platform.dart';
import '../../../live/domain/entities/live_gift_type.dart';

final giftRepositoryProvider = Provider<GiftRepository>((ref) {
  return GiftRepository(ref.watch(dioProvider));
});

final giftSoundServiceProvider = Provider<GiftSoundService>((ref) {
  final svc = GiftSoundService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Mobil katalog — CMS birincil (`/api/gifts/catalog`), oturum boyunca cache.
final liveGiftCatalogProvider = FutureProvider<List<GiftEntity>>((ref) async {
  ref.keepAlive();
  final repo = ref.watch(giftRepositoryProvider);
  return repo.fetchCatalog(platform: GiftPlatform.mobile);
});

/// Sesli oda hediye listesi — CMS katalog (admin panelinden eklenen hediyeler dahil).
final voiceRoomGiftCatalogProvider = FutureProvider.autoDispose<List<GiftEntity>>((ref) async {
  final repo = ref.watch(giftRepositoryProvider);
  final voice = await repo.fetchCatalog(
    platform: GiftPlatform.mobile,
    context: 'voice_room',
  );
  if (voice.isNotEmpty) return voice;
  return ref.watch(liveGiftCatalogProvider.future);
});

/// Canlı yayın hediye listesi.
final liveStreamGiftCatalogProvider = FutureProvider.autoDispose<List<GiftEntity>>((ref) async {
  final repo = ref.watch(giftRepositoryProvider);
  final live = await repo.fetchCatalog(
    platform: GiftPlatform.mobile,
    context: 'live_stream',
  );
  if (live.isNotEmpty) return live;
  return ref.watch(liveGiftCatalogProvider.future);
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
