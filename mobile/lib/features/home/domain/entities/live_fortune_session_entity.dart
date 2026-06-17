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
    this.tellerUserId,
    this.trtcRoomId,
    this.durationMinutes,
    this.totalJeton,
  });

  final String sessionId;
  final String status;
  final String tellerResponse;
  final bool isClient;
  final String? tellerUserId;
  final String? trtcRoomId;
  final int? durationMinutes;
  final int? totalJeton;

  bool get isActive =>
      status == 'active' ||
      status == 'accepted' ||
      tellerResponse == 'accepted';
  bool get isRejected =>
      status == 'ended' ||
      status == 'rejected' ||
      status == 'cancelled' ||
      tellerResponse == 'rejected';
}

/// Falcı seans sohbet mesajı (`/api/teller-chat/{sessionId}`).
class TellerChatMessage {
  const TellerChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.isMine = false,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime? createdAt;
  final bool isMine;
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
    this.trtcRoomIdOverride,
  });

  final String sessionId;
  final LiveFortuneTellerEntity teller;
  final int durationMinutes;
  final int totalJeton;
  final String? tellerUserId;
  final String? clientId;
  final bool isClient;
  final String? trtcRoomIdOverride;

  String get trtcRoomId =>
      (trtcRoomIdOverride?.trim().isNotEmpty == true)
          ? trtcRoomIdOverride!.trim()
          : sessionId;

  LiveFortuneSessionEntity copyWith({
    String? sessionId,
    LiveFortuneTellerEntity? teller,
    int? durationMinutes,
    int? totalJeton,
    String? tellerUserId,
    String? clientId,
    bool? isClient,
    String? trtcRoomIdOverride,
  }) {
    return LiveFortuneSessionEntity(
      sessionId: sessionId ?? this.sessionId,
      teller: teller ?? this.teller,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalJeton: totalJeton ?? this.totalJeton,
      tellerUserId: tellerUserId ?? this.tellerUserId,
      clientId: clientId ?? this.clientId,
      isClient: isClient ?? this.isClient,
      trtcRoomIdOverride: trtcRoomIdOverride ?? this.trtcRoomIdOverride,
    );
  }

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
