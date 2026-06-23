import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/psychic_push_payload.dart';

/// Son push/SSE davet filtresi sonucu — FAZ 1 teşhis.
class PsychicInviteFilterEvent {
  const PsychicInviteFilterEvent({
    required this.sessionId,
    required this.decision,
    required this.at,
    this.source = 'push',
  });

  final String sessionId;
  final PsychicInvitePresentationDecision decision;
  final DateTime at;
  final String source;
}

class PsychicInviteDiagnosticNotifier extends Notifier<PsychicInviteFilterEvent?> {
  @override
  PsychicInviteFilterEvent? build() => null;

  void record({
    required String sessionId,
    required PsychicInvitePresentationDecision decision,
    String source = 'push',
  }) {
    state = PsychicInviteFilterEvent(
      sessionId: sessionId,
      decision: decision,
      at: DateTime.now(),
      source: source,
    );
  }

  void clear() => state = null;
}

final psychicInviteDiagnosticProvider =
    NotifierProvider<PsychicInviteDiagnosticNotifier, PsychicInviteFilterEvent?>(
  PsychicInviteDiagnosticNotifier.new,
);
