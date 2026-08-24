import '../../../core/util/json_util.dart';

/// Backend Gift Engine SSE olay yönlendirmesi (denetim raporu §5.3 / §9).
enum GiftEngineSseAction {
  /// `engine:true` + `event:gift_received` — animasyon/feed.
  visualize,

  /// `engine:true` + `event:gift_queue_updated` — yalnızca kuyruk senkronu.
  queueSync,

  /// `engine:true` + `event:gift_finished` — sıradan çıkar.
  finished,

  /// Legacy payload (`engine` yok) — motor görülmediyse yedek görselleştirme.
  legacyVisualize,

  /// Tekrar veya bilinmeyen motor olayı — işleme.
  skip,
}

/// SSE hediye payload sınıflandırıcı — web ile aynı motor kuralları.
abstract final class GiftEngineSseRouter {
  static GiftEngineSseAction classify(Map<String, dynamic> payload) {
    if (payload['engine'] == true) {
      final event =
          payload['event']?.toString().toLowerCase().trim() ?? '';
      return switch (event) {
        'gift_received' => GiftEngineSseAction.visualize,
        'gift_queue_updated' => GiftEngineSseAction.queueSync,
        'gift_finished' => GiftEngineSseAction.finished,
        _ => GiftEngineSseAction.skip,
      };
    }
    return GiftEngineSseAction.legacyVisualize;
  }

  /// Motor `gift_received` veya legacy yedek için tekil hediye anahtarı.
  static String? dedupeKey(Map<String, dynamic> payload) {
    final direct = pick(payload, [
      'giftHistoryId',
      'historyId',
      'queueItemId',
      'queueId',
      'giftEventId',
    ])?.toString();
    if (direct != null && direct.trim().isNotEmpty) return direct.trim();

    final nested = payload['gift'] ?? payload['giftType'] ?? payload['data'];
    if (nested is Map) {
      final m = asJsonMap(nested);
      final id = pick(m, [
        'giftHistoryId',
        'historyId',
        'queueItemId',
        'id',
      ])?.toString();
      if (id != null && id.trim().isNotEmpty) return id.trim();
    }
    return null;
  }

  /// `gift_finished` veya kuyruk güncellemesi için çıkarılacak öğe kimliği.
  static String? finishedItemId(Map<String, dynamic> payload) {
    return pick(payload, [
      'queueItemId',
      'queueId',
      'giftHistoryId',
      'historyId',
      'id',
      'giftEventId',
    ])?.toString()?.trim();
  }

  /// `gift_queue_updated` içindeki sıra listesi.
  static List<Map<String, dynamic>> queueItems(Map<String, dynamic> payload) {
    final raw = payload['queue'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
