import 'package:equatable/equatable.dart';

import 'psychic_session_status.dart';

/// Falcıya düşen gelen istek — SSE / poll.
class PsychicRequestEntity extends Equatable {
  const PsychicRequestEntity({
    required this.sessionId,
    required this.clientId,
    required this.clientName,
    required this.tellerId,
    this.tellerUserId,
    this.clientAvatarUrl,
    required this.durationMinutes,
    required this.totalJeton,
    required this.fortuneType,
    this.status = PsychicSessionStatus.pending,
  });

  final String sessionId;
  final String clientId;
  final String clientName;
  final String? clientAvatarUrl;
  final String tellerId;
  final String? tellerUserId;
  final int durationMinutes;
  final int totalJeton;
  final String fortuneType;
  final PsychicSessionStatus status;

  bool get isPending => status.isWaiting;

  @override
  List<Object?> get props => [
        sessionId,
        clientId,
        clientName,
        clientAvatarUrl,
        tellerId,
        tellerUserId,
        durationMinutes,
        totalJeton,
        fortuneType,
        status,
      ];
}
