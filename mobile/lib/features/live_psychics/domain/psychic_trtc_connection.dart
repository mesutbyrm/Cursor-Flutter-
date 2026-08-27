import 'psychic_trtc_identity.dart';

/// Psychic TRTC medya bağlantısı — iş/SSE fazından bağımsız.
enum PsychicTrtcPhase {
  idle,
  initializing,
  joining,
  connected,
  reconnecting,
  leaving,
  left,
  disposed,
}

/// Yeniden bağlanma yalnızca gerçek kopuş / ağ dönüşü / odada değilken resume.
enum PsychicTrtcReconnectReason {
  connectionLost,
  networkRecovered,
  appResumedNotInRoom,
}

/// Tek uçuşlu TRTC join/leave/reconnect kapısı.
class PsychicTrtcConnection {
  PsychicTrtcPhase phase = PsychicTrtcPhase.idle;

  String? sessionId;
  String? tokenRequestRoomId;
  String? joinedTrtcRoomId;
  String? joinedUserId;
  String? remoteUserId;

  var _joinInFlight = false;
  var _reconnectInFlight = false;
  var _leaveInFlight = false;

  bool get joinInFlight => _joinInFlight;
  bool get reconnectInFlight => _reconnectInFlight;
  bool get leaveInFlight => _leaveInFlight;
  bool get isBusy => _joinInFlight || _reconnectInFlight || _leaveInFlight;

  bool get isTerminal =>
      phase == PsychicTrtcPhase.leaving ||
      phase == PsychicTrtcPhase.left ||
      phase == PsychicTrtcPhase.disposed;

  /// Aynı oturumda zaten bu TRTC odasındaysak tekrar enterRoom yok.
  bool alreadyJoined({
    required String sessionId,
    required String? trtcRoomId,
    required bool inRoom,
  }) {
    if (!inRoom) return false;
    if (phase != PsychicTrtcPhase.connected &&
        phase != PsychicTrtcPhase.joining) {
      return false;
    }
    if (this.sessionId != null && this.sessionId != sessionId) return false;
    final joined = joinedTrtcRoomId;
    if (joined == null || joined.isEmpty) return false;
    if (trtcRoomId == null || trtcRoomId.isEmpty) return true;
    return PsychicTrtcIdentity.sameChannel(
      joined,
      trtcRoomId,
      sessionId: sessionId,
    );
  }

  bool tryBeginJoin() {
    if (isTerminal || _joinInFlight || _leaveInFlight) {
      return false;
    }
    if (_reconnectInFlight && phase != PsychicTrtcPhase.reconnecting) {
      return false;
    }
    _joinInFlight = true;
    phase = phase == PsychicTrtcPhase.idle ||
            phase == PsychicTrtcPhase.left
        ? PsychicTrtcPhase.initializing
        : PsychicTrtcPhase.joining;
    return true;
  }

  void markJoining() {
    if (isTerminal) return;
    phase = PsychicTrtcPhase.joining;
  }

  void markConnected({
    required String sessionId,
    required String tokenRequestRoomId,
    required String joinedTrtcRoomId,
    required String joinedUserId,
    String? remoteUserId,
  }) {
    this.sessionId = sessionId;
    this.tokenRequestRoomId = tokenRequestRoomId;
    this.joinedTrtcRoomId = joinedTrtcRoomId;
    this.joinedUserId = joinedUserId;
    this.remoteUserId = remoteUserId;
    phase = PsychicTrtcPhase.connected;
    _joinInFlight = false;
    _reconnectInFlight = false;
  }

  void markJoinFailed() {
    _joinInFlight = false;
    _reconnectInFlight = false;
    if (!isTerminal) {
      phase = PsychicTrtcPhase.idle;
    }
  }

  /// SSE oda güncellemesi, remote audio/video, live heartbeat → reconnect yok.
  bool shouldReconnect({
    required PsychicTrtcReconnectReason reason,
    required bool inRoom,
  }) {
    if (isTerminal || _reconnectInFlight || _joinInFlight || _leaveInFlight) {
      return false;
    }
    switch (reason) {
      case PsychicTrtcReconnectReason.connectionLost:
        return phase == PsychicTrtcPhase.connected ||
            phase == PsychicTrtcPhase.joining;
      case PsychicTrtcReconnectReason.networkRecovered:
      case PsychicTrtcReconnectReason.appResumedNotInRoom:
        return !inRoom &&
            (phase == PsychicTrtcPhase.connected ||
                phase == PsychicTrtcPhase.reconnecting);
    }
  }

  bool tryBeginReconnect(PsychicTrtcReconnectReason reason, {required bool inRoom}) {
    if (!shouldReconnect(reason: reason, inRoom: inRoom)) return false;
    _reconnectInFlight = true;
    phase = PsychicTrtcPhase.reconnecting;
    return true;
  }

  void markReconnectFinished() {
    _reconnectInFlight = false;
  }

  bool tryBeginLeave() {
    if (phase == PsychicTrtcPhase.disposed) return false;
    if (_leaveInFlight) return false;
    _leaveInFlight = true;
    _joinInFlight = false;
    _reconnectInFlight = false;
    phase = PsychicTrtcPhase.leaving;
    return true;
  }

  void markLeft() {
    _leaveInFlight = false;
    _joinInFlight = false;
    _reconnectInFlight = false;
    joinedTrtcRoomId = null;
    joinedUserId = null;
    tokenRequestRoomId = null;
    remoteUserId = null;
    phase = PsychicTrtcPhase.left;
  }

  void markDisposed() {
    _leaveInFlight = false;
    _joinInFlight = false;
    _reconnectInFlight = false;
    phase = PsychicTrtcPhase.disposed;
  }

  /// Psychic A → B: eski kilitli oda/token bu oturuma ait değil.
  bool isForeignSession(String nextSessionId) {
    final current = sessionId?.trim() ?? '';
    if (current.isEmpty) return false;
    return current != nextSessionId.trim();
  }

  Map<String, Object?> telemetry({
    String? errorCode,
    String? errorMessage,
    bool? inRoom,
    bool? online,
  }) {
    return {
      'sessionId': sessionId,
      'roomId': tokenRequestRoomId,
      'trtcRoomId': joinedTrtcRoomId,
      'userId': joinedUserId,
      'connectionState': phase.name,
      if (inRoom != null) 'inRoom': inRoom,
      if (online != null) 'online': online,
      if (errorCode != null) 'errorCode': errorCode,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }
}

/// ValueNotifier dinleyicisi tek kez bağlanır.
class PsychicTrtcListenerBind {
  var attached = false;

  bool tryAttach() {
    if (attached) return false;
    attached = true;
    return true;
  }

  bool tryDetach() {
    if (!attached) return false;
    attached = false;
    return true;
  }
}
