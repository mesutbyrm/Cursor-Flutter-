import 'dart:async';

/// Idempotent oda çıkışı — aynı anda iki leave isteği engellenir.
///
/// Sıra: heartbeat/SSE/poll durdur → müzik/ses/video kes → TRTC çık →
/// backend leave → state temizle.
class RoomLeaveCoordinator {
  RoomLeaveCoordinator();

  var _leaving = false;
  bool get isLeaving => _leaving;

  /// [steps] sırayla çalıştırılır; hata olsa bile devam edilir.
  Future<void> leave({
    required String roomId,
    required String source,
    required List<Future<void> Function()> steps,
  }) async {
    if (_leaving) return;
    _leaving = true;
    try {
      for (final step in steps) {
        try {
          await step().timeout(
            const Duration(seconds: 6),
            onTimeout: () {},
          );
        } catch (_) {}
      }
    } finally {
      _leaving = false;
    }
  }

  void reset({bool force = false}) {
    if (!force && _leaving) return;
    _leaving = false;
  }
}
