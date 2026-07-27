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

  static Map<String, dynamic> unwrap(Map<String, dynamic> map) {
    final nested = map['gift'] ?? map['giftType'] ?? map['data'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    return map;
  }
}
