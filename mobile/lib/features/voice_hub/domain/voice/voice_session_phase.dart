/// Sesli oda oturum fazları — JOINING / CONNECTED vb.
enum VoiceSessionPhase {
  idle,
  joining,
  connected,
  reconnecting,
  leaving,
  disconnected,
  error,
}

abstract final class VoiceSessionPhaseGuard {
  static const _allowed = <VoiceSessionPhase, Set<VoiceSessionPhase>>{
    VoiceSessionPhase.idle: {
      VoiceSessionPhase.joining,
      VoiceSessionPhase.error,
    },
    VoiceSessionPhase.joining: {
      VoiceSessionPhase.connected,
      VoiceSessionPhase.reconnecting,
      VoiceSessionPhase.leaving,
      VoiceSessionPhase.disconnected,
      VoiceSessionPhase.error,
    },
    VoiceSessionPhase.connected: {
      VoiceSessionPhase.reconnecting,
      VoiceSessionPhase.leaving,
      VoiceSessionPhase.disconnected,
      VoiceSessionPhase.error,
    },
    VoiceSessionPhase.reconnecting: {
      VoiceSessionPhase.connected,
      VoiceSessionPhase.leaving,
      VoiceSessionPhase.disconnected,
      VoiceSessionPhase.error,
    },
    VoiceSessionPhase.leaving: {
      VoiceSessionPhase.disconnected,
      VoiceSessionPhase.idle,
      VoiceSessionPhase.error,
    },
    VoiceSessionPhase.disconnected: {VoiceSessionPhase.idle},
    VoiceSessionPhase.error: {
      VoiceSessionPhase.idle,
      VoiceSessionPhase.joining,
      VoiceSessionPhase.leaving,
    },
  };

  static bool canTransition(VoiceSessionPhase from, VoiceSessionPhase to) {
    if (from == to) return false;
    return _allowed[from]?.contains(to) ?? false;
  }
}
