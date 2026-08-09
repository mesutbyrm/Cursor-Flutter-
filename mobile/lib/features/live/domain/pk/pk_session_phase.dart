/// PK oturum durum makinesi.
enum PkSessionPhase {
  idle,
  requesting,
  incoming,
  accepting,
  rejecting,
  connecting,
  active,
  reconnecting,
  ending,
  ended,
  rejected,
  error,
}

abstract final class PkSessionPhaseGuard {
  static const _allowed = <PkSessionPhase, Set<PkSessionPhase>>{
    PkSessionPhase.idle: {
      PkSessionPhase.requesting,
      PkSessionPhase.incoming,
      PkSessionPhase.error,
    },
    PkSessionPhase.requesting: {
      PkSessionPhase.incoming,
      PkSessionPhase.connecting,
      PkSessionPhase.rejected,
      PkSessionPhase.ending,
      PkSessionPhase.ended,
      PkSessionPhase.error,
    },
    PkSessionPhase.incoming: {
      PkSessionPhase.accepting,
      PkSessionPhase.rejecting,
      PkSessionPhase.ended,
      PkSessionPhase.rejected,
      PkSessionPhase.error,
    },
    PkSessionPhase.accepting: {
      PkSessionPhase.connecting,
      PkSessionPhase.active,
      PkSessionPhase.rejected,
      PkSessionPhase.error,
    },
    PkSessionPhase.rejecting: {
      PkSessionPhase.rejected,
      PkSessionPhase.ended,
      PkSessionPhase.error,
    },
    PkSessionPhase.connecting: {
      PkSessionPhase.active,
      PkSessionPhase.reconnecting,
      PkSessionPhase.ending,
      PkSessionPhase.ended,
      PkSessionPhase.error,
    },
    PkSessionPhase.active: {
      PkSessionPhase.reconnecting,
      PkSessionPhase.ending,
      PkSessionPhase.ended,
      PkSessionPhase.error,
    },
    PkSessionPhase.reconnecting: {
      PkSessionPhase.active,
      PkSessionPhase.connecting,
      PkSessionPhase.ending,
      PkSessionPhase.ended,
      PkSessionPhase.error,
    },
    PkSessionPhase.ending: {
      PkSessionPhase.ended,
      PkSessionPhase.error,
    },
    PkSessionPhase.ended: {PkSessionPhase.idle},
    PkSessionPhase.rejected: {PkSessionPhase.idle},
    PkSessionPhase.error: {
      PkSessionPhase.idle,
      PkSessionPhase.requesting,
      PkSessionPhase.incoming,
      PkSessionPhase.ending,
      PkSessionPhase.ended,
    },
  };

  static bool canTransition(PkSessionPhase from, PkSessionPhase to) {
    if (from == to) return false;
    return _allowed[from]?.contains(to) ?? false;
  }
}
