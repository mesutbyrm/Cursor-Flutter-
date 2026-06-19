import 'dart:async';

/// SSE yeniden bağlanma politikası — tüm stream servisleri için ortak.
abstract final class SseReconnectPolicy {
  static const baseDelay = Duration(seconds: 2);
  static const maxDelay = Duration(seconds: 12);
  static const maxAttempts = 0; // 0 = sınırsız

  static Duration delayForAttempt(int attempt) {
    final sec = baseDelay.inSeconds * (attempt.clamp(1, 6));
    return Duration(seconds: sec.clamp(baseDelay.inSeconds, maxDelay.inSeconds));
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
