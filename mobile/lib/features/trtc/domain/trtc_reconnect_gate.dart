/// TRTC bağlantı durum makinesi — tek oturum, çift reconnect yasak.
enum TrtcConnectionPhase {
  idle,
  signaling,
  connecting,
  connected,
  reconnecting,
  disconnected,
  closed,
}

/// SDK geçici ICE kopması ile gerçek kopmayı ayırır.
///
/// `onConnectionLost` sonrası Tencent SDK kendi `onTryToReconnect` /
/// `onConnectionRecovery` döngüsünü çalıştırır. Uygulama hemen `leave+join`
/// yaparsa iki taraf bağımsız reconnect'e girer (5 sn donma).
class TrtcReconnectGate {
  TrtcReconnectGate({this.sdkGrace = const Duration(seconds: 8)});

  /// SDK'nın kendi yeniden bağlanma denemesine tanınan süre.
  final Duration sdkGrace;

  TrtcConnectionPhase phase = TrtcConnectionPhase.idle;
  DateTime? lostAt;
  var hardReconnectInFlight = false;
  var generation = 0;

  bool get isLive =>
      phase == TrtcConnectionPhase.connecting ||
      phase == TrtcConnectionPhase.connected ||
      phase == TrtcConnectionPhase.reconnecting;

  void reset() {
    phase = TrtcConnectionPhase.idle;
    lostAt = null;
    hardReconnectInFlight = false;
    generation++;
  }

  void onJoinStarted() {
    if (phase == TrtcConnectionPhase.closed) {
      phase = TrtcConnectionPhase.idle;
    }
    generation++;
    hardReconnectInFlight = false;
    lostAt = null;
    phase = TrtcConnectionPhase.signaling;
  }

  void onConnecting() {
    if (phase == TrtcConnectionPhase.closed) return;
    phase = TrtcConnectionPhase.connecting;
  }

  void onConnected() {
    if (phase == TrtcConnectionPhase.closed) return;
    phase = TrtcConnectionPhase.connected;
    lostAt = null;
    hardReconnectInFlight = false;
  }

  /// SDK `onConnectionLost` — henüz odayı bırakma.
  void onSdkConnectionLost() {
    if (phase == TrtcConnectionPhase.closed ||
        phase == TrtcConnectionPhase.idle) {
      return;
    }
    if (phase == TrtcConnectionPhase.connected ||
        phase == TrtcConnectionPhase.connecting) {
      phase = TrtcConnectionPhase.reconnecting;
      lostAt ??= DateTime.now();
    }
  }

  /// SDK `onTryToReconnect` — uygulama hard reconnect başlatmasın.
  void onSdkTryToReconnect() {
    if (phase == TrtcConnectionPhase.closed) return;
    phase = TrtcConnectionPhase.reconnecting;
    lostAt ??= DateTime.now();
  }

  /// SDK `onConnectionRecovery` — grace timer iptal.
  void onSdkRecovered() {
    if (phase == TrtcConnectionPhase.closed) return;
    phase = TrtcConnectionPhase.connected;
    lostAt = null;
    hardReconnectInFlight = false;
  }

  /// Grace dolduysa uygulama `leave+join` yapabilir.
  bool get shouldHardReconnect {
    if (hardReconnectInFlight) return false;
    if (phase == TrtcConnectionPhase.closed ||
        phase == TrtcConnectionPhase.idle ||
        phase == TrtcConnectionPhase.connected) {
      return false;
    }
    final lost = lostAt;
    if (lost == null) return false;
    return DateTime.now().difference(lost) >= sdkGrace;
  }

  void markHardReconnectStarted() {
    hardReconnectInFlight = true;
    phase = TrtcConnectionPhase.reconnecting;
  }

  void onHardReconnectFinished({required bool success}) {
    hardReconnectInFlight = false;
    if (success) {
      phase = TrtcConnectionPhase.connected;
      lostAt = null;
    } else {
      phase = TrtcConnectionPhase.disconnected;
    }
  }

  void onClosed() {
    phase = TrtcConnectionPhase.closed;
    lostAt = null;
    hardReconnectInFlight = false;
    generation++;
  }
}
