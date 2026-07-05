import '../../../core/util/json_util.dart';

/// Destekçi rozeti kademesi (Yeni → Bronz → … → Efsane).
class SupporterTier {
  const SupporterTier({
    required this.code,
    required this.label,
    this.min = 0,
    this.remaining,
  });

  factory SupporterTier.fromJson(Map<String, dynamic> json) {
    return SupporterTier(
      code: (pick(json, ['code', 'id']) ?? '').toString(),
      label: (pick(json, ['label', 'name']) ?? '').toString(),
      min: asInt(pick(json, ['min', 'minAmount', 'threshold'])),
      remaining: json.containsKey('remaining')
          ? asInt(pick(json, ['remaining']))
          : null,
    );
  }

  final String code;
  final String label;
  final int min;

  /// Bir sonraki kademeye kalan (yalnızca nextBadge için dolu).
  final int? remaining;
}

/// Kullanıcının destekçi rozeti durumu — `/api/gifts/insights/badge/{id}`
/// veya `/api/gifts/insights/me/badge`.
class SupporterBadge {
  const SupporterBadge({
    required this.totalSent,
    required this.totalSentDisplay,
    required this.totalGifts,
    this.current,
    this.next,
    this.allTiers = const [],
  });

  factory SupporterBadge.fromJson(Map<String, dynamic> json) {
    final badge = pick(json, ['badge', 'current', 'tier']);
    final nextRaw = pick(json, ['nextBadge', 'next']);
    final tiersRaw = pick(json, ['allTiers', 'tiers']);
    final tiers = <SupporterTier>[];
    if (tiersRaw is List) {
      for (final e in tiersRaw) {
        if (e is Map) tiers.add(SupporterTier.fromJson(asJsonMap(e)));
      }
    }
    return SupporterBadge(
      totalSent: asInt(pick(json, ['totalSent', 'total', 'coins'])),
      totalSentDisplay:
          (pick(json, ['totalSentDisplay', 'totalDisplay']) ?? '0').toString(),
      totalGifts: asInt(pick(json, ['totalGifts', 'giftCount'])),
      current: badge is Map ? SupporterTier.fromJson(asJsonMap(badge)) : null,
      next: nextRaw is Map ? SupporterTier.fromJson(asJsonMap(nextRaw)) : null,
      allTiers: tiers,
    );
  }

  final int totalSent;
  final String totalSentDisplay;
  final int totalGifts;
  final SupporterTier? current;
  final SupporterTier? next;
  final List<SupporterTier> allTiers;

  /// Mevcut kademe → sonraki kademe arası ilerleme (0..1).
  double get progressToNext {
    final n = next;
    final c = current;
    if (n == null || c == null || n.min <= c.min) return 1;
    final span = n.min - c.min;
    final done = (totalSent - c.min).clamp(0, span);
    return span <= 0 ? 1 : (done / span).clamp(0.0, 1.0);
  }
}
