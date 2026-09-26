import 'dart:async';
import 'dart:math';

/// SSE yeniden bağlanma politikası — tüm stream servisleri için ortak.
///
/// Gecikme dizisi: 0ms → 100ms → 300ms → 800ms → 2s → 5s (maksimum) + %10 jitter.
/// P0: Connection drops sorununu çöz — aggressive reconnect.
abstract final class SseReconnectPolicy {
  static const _delaysSec = [0, 0, 1, 1, 2, 5];
  static const maxDelay = Duration(seconds: 30);
  static final _rng = Random();

  static Duration delayForAttempt(int attempt) {
    final idx = (attempt - 1).clamp(0, _delaysSec.length - 1);
    var base = Duration(seconds: _delaysSec[idx]);
    // Tablo bittikten sonra üstel olarak yavaşla (5→10→20→30 sn). Sabit 5 sn'de
    // kalmak uzun kesintilerde sunucuyu gereksiz dövüyordu.
    if (attempt > _delaysSec.length) {
      final steps = (attempt - _delaysSec.length).clamp(0, 3);
      final seconds = _delaysSec.last << steps;
      base = Duration(seconds: seconds);
      if (base > maxDelay) base = maxDelay;
    }
    // Azaltılmış jitter: 30% → 10% (reconnect'leri tahmin edilebilir hale getir)
    final jitterMs = (base.inMilliseconds * 0.1 * _rng.nextDouble()).round();
    return base + Duration(milliseconds: jitterMs);
  }

  /// Oda/yayın akışları kullanıcı odadan çıkana kadar yaşamalı; deneme sayısına
  /// bakıp kalıcı vazgeçmek, kısa bir şebeke kesintisinden sonra SSE'yi oturum
  /// boyunca ölü bırakıyordu (`_reconnectAttempt` yalnızca başarılı bağlantıda
  /// sıfırlanır). Terminal durumlar — yenilenemeyen 401 ve reconnect'e kapalı
  /// HTTP kodları — zaten ayrı `failed` yolundan ele alınır.
  static bool shouldGiveUp(int attempt) => false;
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
