import 'package:flutter/foundation.dart';

import 'cf_diag.dart';

/// Otomatik hata tespit kuralları — `docs/CANLIFAL_DIAGNOSTIC_SYSTEM_SPEC.md` §3.
///
/// Her kural ihlalde `CfDiag`'e `CRITICAL <KURAL>` kaydı düşer (seviye error)
/// ve `true` döner. Aynı kural + anahtar için [cooldown] içinde tekrar
/// kaydedilmez (saniyelik sayaçlar günlüğü doldurmasın). Kimlik bilgisi
/// yazılmaz; yalnız oda/seans kimlikleri ve sayılar.
abstract final class CfAutoDetect {
  static const cooldown = Duration(seconds: 30);
  static const timerDriftThreshold = 2;

  static final _lastFired = <String, DateTime>{};

  static bool _fire(
    String rule,
    String key,
    CfCategory category,
    Map<String, Object?> data,
  ) {
    final k = '$rule|$key';
    final now = DateTime.now();
    final last = _lastFired[k];
    if (last != null && now.difference(last) < cooldown) return true;
    _lastFired[k] = now;
    CfDiag.record(category, 'CRITICAL $rule', level: CfLevel.error, data: data);
    return true;
  }

  /// TIMER_DRIFT — `|istemci − sunucu| > 2 sn`.
  static bool timerDrift({
    required String sessionId,
    required int clientRemaining,
    required int serverRemaining,
  }) {
    final diff = (clientRemaining - serverRemaining).abs();
    if (diff <= timerDriftThreshold) return false;
    return _fire('TIMER_DRIFT', sessionId, CfCategory.fortune, {
      'sessionId': sessionId,
      'client': clientRemaining,
      'server': serverRemaining,
      'diff': diff,
    });
  }

  /// AUDIO_ACTIVE_WITHOUT_SEAT — sesli odada yayın (koltuk) yokken yerel ses açık.
  static bool audioWithoutSeat({
    required String roomId,
    required bool publishing,
    required bool localAudioOn,
  }) {
    if (publishing || !localAudioOn) return false;
    return _fire('AUDIO_ACTIVE_WITHOUT_SEAT', roomId, CfCategory.voice, {
      'roomId': roomId,
    });
  }

  /// TRTC_JOINED_TWICE — bir oturum odadayken başka yönetici `enterRoom` istedi.
  static bool trtcJoinedTwice({
    required String activeRoomId,
    required String newRoomId,
  }) {
    return _fire('TRTC_JOINED_TWICE', newRoomId, CfCategory.trtc, {
      'activeRoomId': activeRoomId,
      'newRoomId': newRoomId,
    });
  }

  /// DUPLICATE_GIFT — aynı `giftHistoryId` ikinci kez oynatılmak üzere.
  static bool duplicateGift({
    required String roomId,
    required String giftEventId,
  }) {
    return _fire('DUPLICATE_GIFT', giftEventId, CfCategory.gift, {
      'roomId': roomId,
      'giftEventId': giftEventId,
    });
  }

  @visibleForTesting
  static void resetForTest() => _lastFired.clear();
}
