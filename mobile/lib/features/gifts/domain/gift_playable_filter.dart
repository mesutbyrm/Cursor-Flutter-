import 'gift_entity.dart';

/// Oynatılabilir hediye listesi — sesli oda / canlı yayın (hediye sistemi dokümanı).
abstract final class GiftPlayableFilter {
  static List<GiftEntity> forContext(
    List<GiftEntity> gifts, {
    required String context,
  }) {
    final out = <GiftEntity>[];
    final seen = <String>{};
    for (final g in gifts) {
      if (!_isPlayable(g, context: context)) continue;
      if (!seen.add(g.id)) continue;
      out.add(g);
    }
    // Her zaman jeton fiyatına göre: 1 → 100K.
    out.sort((a, b) {
      final byPrice = a.price.compareTo(b.price);
      if (byPrice != 0) return byPrice;
      return a.name.compareTo(b.name);
    });
    return out;
  }

  static List<GiftEntity> mergeContexts(
    List<GiftEntity> primary,
    List<GiftEntity> fallback, {
    required String context,
  }) {
    final map = <String, GiftEntity>{};
    for (final g in fallback) {
      map[g.id] = g;
    }
    for (final g in primary) {
      map[g.id] = g;
    }
    return forContext(map.values.toList(), context: context);
  }

  static bool _isPlayable(GiftEntity g, {required String context}) {
    if (g.id.isEmpty || g.name.trim().isEmpty) return false;
    if (!g.isActive || g.isHidden) return false;
    if (context == 'all') return g.price > 0;
    if (context == 'voice_room' && !g.visibleInVoiceRoom) return false;
    if (context == 'live_stream' && !g.visibleInLiveStream) return false;
    return g.price > 0;
  }
}
