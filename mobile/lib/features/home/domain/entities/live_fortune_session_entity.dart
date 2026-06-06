import 'live_fortune_teller_entity.dart';

/// Canlı fal oturumu — TRTC oda + süre/jeton.
class LiveFortuneSessionEntity {
  const LiveFortuneSessionEntity({
    required this.sessionId,
    required this.teller,
    required this.durationMinutes,
    required this.totalJeton,
    this.isClient = true,
  });

  final String sessionId;
  final LiveFortuneTellerEntity teller;
  final int durationMinutes;
  final int totalJeton;
  final bool isClient;

  String get trtcRoomId => sessionId;
}

/// Randevu süre seçenekleri (dakika → jeton/dk).
class FortuneSessionDurationOption {
  const FortuneSessionDurationOption({
    required this.minutes,
    required this.jetonPerMinute,
  });

  final int minutes;
  final int jetonPerMinute;

  int get totalJeton => minutes * jetonPerMinute;

  String get label => '$minutes dakika';

  static List<FortuneSessionDurationOption> forTeller(
    LiveFortuneTellerEntity teller,
  ) {
    final perMin = teller.pricePerMinute > 0 ? teller.pricePerMinute : 10;
    return [5, 10, 15, 20, 30, 60]
        .map((m) => FortuneSessionDurationOption(minutes: m, jetonPerMinute: perMin))
        .toList();
  }
}
