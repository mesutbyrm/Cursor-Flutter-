import 'live_fortune_teller_entity.dart';

/// Bekleyen falcı daveti.
class FortuneIncomingSession {
  const FortuneIncomingSession({
    required this.sessionId,
    required this.clientId,
    required this.clientName,
    required this.tellerId,
    required this.durationMinutes,
    required this.totalJeton,
    required this.category,
    this.status = 'pending',
    this.tellerResponse = 'pending',
  });

  final String sessionId;
  final String clientId;
  final String clientName;
  final String tellerId;
  final int durationMinutes;
  final int totalJeton;
  final String category;
  final String status;
  final String tellerResponse;
}

/// Oturum durumu poll yanıtı.
class FortuneSessionStatusResult {
  const FortuneSessionStatusResult({
    required this.sessionId,
    required this.status,
    required this.tellerResponse,
    required this.isClient,
  });

  final String sessionId;
  final String status;
  final String tellerResponse;
  final bool isClient;

  bool get isActive => status == 'active' || tellerResponse == 'accepted';
  bool get isRejected =>
      status == 'ended' || tellerResponse == 'rejected';
}

/// `POST /api/fortune-tellers/session` yanıtı.
class FortuneSessionCreateResult {
  const FortuneSessionCreateResult({
    required this.sessionId,
    required this.status,
    this.tellerUserId,
    this.clientId,
    this.role,
    this.isClient = true,
  });

  final String sessionId;
  final String status;
  final String? tellerUserId;
  final String? clientId;
  final String? role;
  final bool isClient;
}

/// Canlı fal oturumu — TRTC oda + süre/jeton.
class LiveFortuneSessionEntity {
  const LiveFortuneSessionEntity({
    required this.sessionId,
    required this.teller,
    required this.durationMinutes,
    required this.totalJeton,
    this.tellerUserId,
    this.clientId,
    this.isClient = true,
  });

  final String sessionId;
  final LiveFortuneTellerEntity teller;
  final int durationMinutes;
  final int totalJeton;
  final String? tellerUserId;
  final String? clientId;
  final bool isClient;

  String get trtcRoomId => sessionId;

  String get anchorUserId {
    final fromSession = tellerUserId?.trim();
    if (fromSession != null && fromSession.isNotEmpty) return fromSession;
    return teller.trtcUserId;
  }
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
