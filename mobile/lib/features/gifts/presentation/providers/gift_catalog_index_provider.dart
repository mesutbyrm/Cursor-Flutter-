import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_entity.dart';
import 'gift_providers.dart';

/// Hediye kimliği → CMS katalog satırı (animasyon/ses çözümlemesi için).
final giftCatalogByIdProvider = Provider<Map<String, GiftEntity>>((ref) {
  final async = ref.watch(liveGiftCatalogProvider);
  return async.maybeWhen(
    data: (gifts) => {for (final g in gifts) g.id: g},
    orElse: () => const {},
  );
});

GiftEntity? lookupGiftCatalog(Map<String, GiftEntity> index, String giftId) {
  if (giftId.isEmpty) return null;
  return index[giftId] ?? index[giftId.toLowerCase()];
}
