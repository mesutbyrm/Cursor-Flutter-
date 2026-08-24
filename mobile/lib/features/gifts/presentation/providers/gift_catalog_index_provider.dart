import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/gift_entity.dart';
import 'gift_providers.dart';

/// Birleşik hediye kataloğu — sesli oda + canlı yayın + genel CMS.
final allGiftCatalogByIdProvider = Provider<Map<String, GiftEntity>>((ref) {
  final map = <String, GiftEntity>{};
  void addAll(List<GiftEntity> gifts) {
    for (final g in gifts) {
      map[g.id] = g;
      map.putIfAbsent(g.id.toLowerCase(), () => g);
    }
  }

  addAll(ref.watch(liveGiftCatalogProvider).valueOrNull ?? const []);
  addAll(ref.watch(voiceRoomGiftCatalogProvider).valueOrNull ?? const []);
  addAll(ref.watch(liveStreamGiftCatalogProvider).valueOrNull ?? const []);
  return map;
});

/// Hediye kimliği → CMS katalog satırı (animasyon/ses çözümlemesi için).
final giftCatalogByIdProvider = Provider<Map<String, GiftEntity>>((ref) {
  return ref.watch(allGiftCatalogByIdProvider);
});

GiftEntity? lookupGiftCatalog(Map<String, GiftEntity> index, String giftId) {
  if (giftId.isEmpty) return null;
  return index[giftId] ?? index[giftId.toLowerCase()];
}
