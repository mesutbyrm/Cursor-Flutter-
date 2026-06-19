import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seans bittiğinde gösterilecek özet (push veya oturum çıkışı).
class PsychicSessionEndedEvent {
  const PsychicSessionEndedEvent({
    required this.sessionId,
    this.tellerId,
    this.tellerName,
    this.durationMinutes,
    this.totalJeton,
    this.message,
    this.promptReview = false,
  });

  final String sessionId;
  final String? tellerId;
  final String? tellerName;
  final int? durationMinutes;
  final int? totalJeton;
  final String? message;
  final bool promptReview;
}

final psychicSessionEndedProvider =
    StateProvider<PsychicSessionEndedEvent?>((ref) => null);
