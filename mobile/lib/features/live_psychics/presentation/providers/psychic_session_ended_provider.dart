import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seans bittiğinde gösterilecek özet (push veya oturum çıkışı).
class PsychicSessionEndedEvent {
  const PsychicSessionEndedEvent({
    required this.sessionId,
    this.tellerId,
    this.tellerName,
    this.durationMinutes,
    this.totalJeton,
    this.tipsJeton,
    this.message,
    this.promptReview = false,
    this.navigateAfter = false,
    this.isTeller = false,
  });

  final String sessionId;
  final String? tellerId;
  final String? tellerName;
  final int? durationMinutes;
  final int? totalJeton;
  final int? tipsJeton;
  final String? message;
  final bool promptReview;
  final bool navigateAfter;
  final bool isTeller;
}

final psychicSessionEndedProvider =
    StateProvider<PsychicSessionEndedEvent?>((ref) => null);
