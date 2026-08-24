import 'psychic_session_status.dart';

/// `GET /api/fortune-tellers/session` — kullanıcının son seansları.
class PsychicSessionHistoryEntity {
  const PsychicSessionHistoryEntity({
    required this.sessionId,
    required this.status,
    this.fortuneType = 'general',
    this.creditsCharged = 0,
    this.maxMinutes = 0,
    this.minutesUsed,
    this.createdAt,
    this.tellerId,
    this.tellerName,
    this.tellerAvatarUrl,
    this.clientName,
    this.clientAvatarUrl,
  });

  final String sessionId;
  final PsychicSessionStatus status;
  final String fortuneType;
  final int creditsCharged;
  final int maxMinutes;
  final int? minutesUsed;
  final DateTime? createdAt;
  final String? tellerId;
  final String? tellerName;
  final String? tellerAvatarUrl;
  final String? clientName;
  final String? clientAvatarUrl;
}
