import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/presentation/gifts/providers/live_gift_providers.dart';
import '../../../voice_hub/presentation/widgets/voice_room_gift_sheet.dart';
import '../../data/gift_repository.dart';
import '../../domain/gift_entity.dart';
import 'gift_catalog_index_provider.dart';
import 'gift_providers.dart';

/// Tüm public hediye katalog provider'larını yenile (admin kaydı sonrası).
Future<void> invalidateAllGiftCatalogs(WidgetRef ref) async {
  await ref.read(giftRepositoryProvider).bustCatalogCache();
  ref.invalidate(liveGiftCatalogProvider);
  ref.invalidate(voiceRoomGiftCatalogProvider);
  ref.invalidate(liveStreamGiftCatalogProvider);
  ref.invalidate(voiceRoomGiftTypesProvider);
  ref.invalidate(liveGiftTypesProvider);
}

/// Provider invalidate — repository erişimi olmayan yerler için.
void invalidateGiftCatalogProviders(Ref ref) {
  ref.invalidate(liveGiftCatalogProvider);
  ref.invalidate(voiceRoomGiftCatalogProvider);
  ref.invalidate(liveStreamGiftCatalogProvider);
  ref.invalidate(voiceRoomGiftTypesProvider);
  ref.invalidate(liveGiftTypesProvider);
}

/// SSE/animasyon için katalogdan hediye çöz.
GiftEntity? resolveGiftForPlayback(WidgetRef ref, String giftId) {
  return lookupGiftCatalog(ref.watch(giftCatalogByIdProvider), giftId);
}
