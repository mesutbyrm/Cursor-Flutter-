/// Canlı fal seansı durum makinesi — geçersiz geçişler engellenir.
enum PsychicSessionPhase {
  idle,
  requesting,
  incomingRequest,
  accepting,
  rejecting,
  joining,
  connected,
  reconnecting,
  ending,
  ended,
  error,
}

abstract final class PsychicSessionPhaseGuard {
  static const _allowed = <PsychicSessionPhase, Set<PsychicSessionPhase>>{
    PsychicSessionPhase.idle: {
      PsychicSessionPhase.requesting,
      PsychicSessionPhase.incomingRequest,
      PsychicSessionPhase.joining,
      PsychicSessionPhase.error,
    },
    PsychicSessionPhase.requesting: {
      PsychicSessionPhase.incomingRequest,
      PsychicSessionPhase.joining,
      PsychicSessionPhase.ending,
      PsychicSessionPhase.ended,
      PsychicSessionPhase.error,
    },
    PsychicSessionPhase.incomingRequest: {
      PsychicSessionPhase.accepting,
      PsychicSessionPhase.rejecting,
      PsychicSessionPhase.ending,
      PsychicSessionPhase.ended,
      PsychicSessionPhase.error,
    },
    PsychicSessionPhase.accepting: {
      PsychicSessionPhase.joining,
      PsychicSessionPhase.ended,
      PsychicSessionPhase.error,
    },
    PsychicSessionPhase.rejecting: {
      PsychicSessionPhase.ended,
      PsychicSessionPhase.error,
    },
    PsychicSessionPhase.joining: {
      PsychicSessionPhase.connected,
      PsychicSessionPhase.reconnecting,
      PsychicSessionPhase.ending,
      PsychicSessionPhase.ended,
      PsychicSessionPhase.error,
    },
    PsychicSessionPhase.connected: {
      PsychicSessionPhase.reconnecting,
      PsychicSessionPhase.ending,
      PsychicSessionPhase.ended,
      PsychicSessionPhase.error,
    },
    PsychicSessionPhase.reconnecting: {
      PsychicSessionPhase.connected,
      PsychicSessionPhase.joining,
      PsychicSessionPhase.ending,
      PsychicSessionPhase.ended,
      PsychicSessionPhase.error,
    },
    PsychicSessionPhase.ending: {
      PsychicSessionPhase.ended,
      PsychicSessionPhase.error,
    },
    PsychicSessionPhase.ended: {PsychicSessionPhase.idle},
    PsychicSessionPhase.error: {
      PsychicSessionPhase.idle,
      PsychicSessionPhase.joining,
      PsychicSessionPhase.reconnecting,
      PsychicSessionPhase.ending,
      PsychicSessionPhase.ended,
    },
  };

  static bool canTransition(PsychicSessionPhase from, PsychicSessionPhase to) {
    if (from == to) return true;
    return _allowed[from]?.contains(to) ?? false;
  }

  static PsychicSessionPhase? transition(
    PsychicSessionPhase from,
    PsychicSessionPhase to,
  ) {
    if (!canTransition(from, to)) return null;
    return to;
  }
}
