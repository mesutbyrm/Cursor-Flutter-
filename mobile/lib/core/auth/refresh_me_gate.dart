/// `refreshMe` / `/api/me` eşzamanlı ve sık tekrarlayan çağrıları sınırlar.
class RefreshMeGate {
  RefreshMeGate({this.minInterval = const Duration(seconds: 8)});

  final Duration minInterval;
  Future<void>? _inFlight;
  DateTime? _lastCompletedAt;

  /// [force] true ise throttle ve paylaşımlı in-flight atlanır.
  Future<void> run(
    Future<void> Function() action, {
    bool force = false,
  }) async {
    if (!force) {
      final last = _lastCompletedAt;
      if (last != null &&
          DateTime.now().difference(last) < minInterval) {
        return;
      }
      final inFlight = _inFlight;
      if (inFlight != null) {
        return inFlight;
      }
    }

    final task = action();
    _inFlight = task;
    try {
      await task;
    } finally {
      if (identical(_inFlight, task)) {
        _inFlight = null;
      }
      _lastCompletedAt = DateTime.now();
    }
  }

  void reset() {
    _inFlight = null;
    _lastCompletedAt = null;
  }
}
