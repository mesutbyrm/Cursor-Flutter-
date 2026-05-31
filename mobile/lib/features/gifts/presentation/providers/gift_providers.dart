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

/// Mobil katalog — lazy, platform=mobile.
final liveGiftCatalogProvider =
    FutureProvider.autoDispose<List<GiftEntity>>((ref) async {
  final repo = ref.watch(giftRepositoryProvider);
  try {
    return await repo.fetchCatalog(platform: GiftPlatform.mobile);
  } catch (_) {
    return repo.fetchCatalogV2(platform: GiftPlatform.mobile);
  }
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
