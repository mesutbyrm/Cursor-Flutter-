import 'dart:async';

/// SSE yeniden bağlanma politikası — tüm stream servisleri için ortak.
///
/// Gecikme dizisi: 1s → 2s → 5s → 10s → 20s → 30s (maksimum).
abstract final class SseReconnectPolicy {
  static const _delaysSec = [1, 2, 5, 10, 20, 30];
  static const maxDelay = Duration(seconds: 30);
  /// Kılavuz §6: maksimum 20 deneme; sonrası failed.
  static const maxAttempts = 20;

  static Duration delayForAttempt(int attempt) {
    final idx = (attempt - 1).clamp(0, _delaysSec.length - 1);
    return Duration(seconds: _delaysSec[idx]);
  }

  static bool shouldGiveUp(int attempt) =>
      maxAttempts > 0 && attempt > maxAttempts;
}

/// Yeniden bağlanma durumu — UI banner / snackbar için.
enum SseConnectionPhase {
  idle,
  connecting,
  connected,
  reconnecting,
  failed,
}

class SseConnectionStatus {
  const SseConnectionStatus({
    required this.phase,
    this.attempt = 0,
    this.lastError,
  });

  final SseConnectionPhase phase;
  final int attempt;
  final Object? lastError;

  bool get isLive =>
      phase == SseConnectionPhase.connected ||
      phase == SseConnectionPhase.connecting;

  SseConnectionStatus copyWith({
    SseConnectionPhase? phase,
    int? attempt,
    Object? lastError,
  }) {
    return SseConnectionStatus(
      phase: phase ?? this.phase,
      attempt: attempt ?? this.attempt,
      lastError: lastError ?? this.lastError,
    );
  }
}

class SseStatusController {
  SseStatusController() : _controller = StreamController.broadcast();

  final StreamController<SseConnectionStatus> _controller;
  SseConnectionStatus _current = const SseConnectionStatus(
    phase: SseConnectionPhase.idle,
  );

  Stream<SseConnectionStatus> get stream => _controller.stream;
  SseConnectionStatus get value => _current;

  void emit(SseConnectionStatus status) {
    _current = status;
    if (!_controller.isClosed) _controller.add(status);
  }

  void dispose() {
    _controller.close();
  }
}
