/// Canlı fal süre el sıkışması — süre (ve ücret) yalnızca her iki taraf odaya
/// bağlandıktan ve DANIŞAN onayladıktan sonra başlar.
///
/// Akış:
///  1. Falcı + danışan TRTC odasına girer (A/V gizli/susturulmuş).
///  2. Falcı, danışanın odada olduğunu görünce `timer_start_request` sinyali yollar.
///  3. Danışan onaylayınca `timer_start_accept` sinyali döner.
///  4. Falcı `start_timer` çağırır → sunucu `timerStarted=true` yayınlar → A/V açılır.
///
/// Bu sınıf yalnızca KARAR verir (yan etkisiz), böylece birim testi kolaydır.
abstract final class PsychicTimerHandshake {
  static const signalRequest = 'timer_start_request';
  static const signalAccept = 'timer_start_accept';

  /// Falcı, danışana süre başlatma isteği göndermeli mi?
  /// Koşullar: falcıyız + süre başlamadı + istek daha önce gönderilmedi +
  /// karşı taraf (danışan) odaya girdi.
  static bool tellerShouldSendRequest({
    required bool isClient,
    required bool timerStarted,
    required bool requestAlreadySent,
    required bool peerPresent,
  }) {
    if (isClient) return false;
    if (timerStarted) return false;
    if (requestAlreadySent) return false;
    return peerPresent;
  }

  /// Danışana onay istemi (dialog) gösterilmeli mi?
  static bool clientShouldPrompt({
    required bool isClient,
    required bool timerStarted,
    required bool promptAlreadyShown,
  }) {
    if (!isClient) return false;
    if (timerStarted) return false;
    return !promptAlreadyShown;
  }

  /// Falcı, danışanın onayı üzerine `start_timer` çağırmalı mı?
  static bool tellerShouldStartTimer({
    required bool isClient,
    required bool timerStarted,
  }) {
    return !isClient && !timerStarted;
  }

  /// Süre başlamadan önce yerel/uzak A/V susturulup gizlenmeli mi?
  static bool shouldGateMedia({required bool timerStarted}) => !timerStarted;

  /// GET/POST `/api/room/signal` — `type` kökte veya `data.action` içinde olabilir.
  static bool signalMatches(Map<String, dynamic> sig, String needle) {
    final n = needle.trim().toLowerCase();
    if (n.isEmpty) return false;
    final parts = <String>[
      sig['type']?.toString() ?? '',
      sig['signalType']?.toString() ?? '',
      sig['event']?.toString() ?? '',
    ];
    for (final key in ['data', 'signalData', 'payload', 'body']) {
      final nested = sig[key];
      if (nested is Map) {
        final m = Map<String, dynamic>.from(nested);
        parts.add(m['type']?.toString() ?? '');
        parts.add(m['action']?.toString() ?? '');
        parts.add(m['signalType']?.toString() ?? '');
      } else if (nested is String && nested.trim().isNotEmpty) {
        parts.add(nested);
      }
    }
    return parts.join(' ').toLowerCase().contains(n);
  }
}
