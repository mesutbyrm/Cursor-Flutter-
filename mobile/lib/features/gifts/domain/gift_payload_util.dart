import '../../../core/util/json_util.dart';

/// SSE / Socket hediye payload birleştirme.
abstract final class GiftPayloadUtil {
  static bool looksLikeGift(Map<String, dynamic> map) {
    if (map.containsKey('giftTypeId') ||
        map.containsKey('giftId') ||
        map.containsKey('giftName')) {
      return true;
    }
    final nested = map['gift'] ?? map['giftType'] ?? map['data'];
    if (nested is Map) {
      final m = asJsonMap(nested);
      return pick(m, ['id', 'giftTypeId', 'giftId', 'name', 'giftName']) != null;
    }
    final type = map['type']?.toString().toLowerCase().trim() ?? '';
    return type.contains('gift');
  }

  /// Dış zarf + iç hediye birleştir — sender/jeton alanları kaybolmaz.
  static Map<String, dynamic> mergeEnvelope(Map<String, dynamic> outer) {
    final nested = outer['gift'] ?? outer['giftType'] ?? outer['data'];
    if (nested is! Map) return outer;
    final inner = asJsonMap(nested);
    final merged = Map<String, dynamic>.from(inner);
    for (final entry in outer.entries) {
      if (entry.key == 'gift' ||
          entry.key == 'giftType' ||
          entry.key == 'data') {
        continue;
      }
      final v = entry.value;
      if (v == null) continue;
      if (!merged.containsKey(entry.key) || _isEmpty(merged[entry.key])) {
        merged[entry.key] = v;
      }
    }
    return merged;
  }

  static Map<String, dynamic> unwrap(Map<String, dynamic> map) =>
      mergeEnvelope(map);

  static bool _isEmpty(dynamic v) {
    if (v == null) return true;
    if (v is String) return v.trim().isEmpty;
    if (v is num) return v == 0;
    return false;
  }
}
