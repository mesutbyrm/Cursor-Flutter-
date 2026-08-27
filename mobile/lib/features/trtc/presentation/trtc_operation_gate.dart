import 'dart:async';

/// Aynı TRTC engine üzerinde eşzamanlı join/leave/reconnect'i sıraya alır.
class TrtcOperationGate {
  Future<void> _tail = Future<void>.value();
  var _inFlight = 0;

  bool get isBusy => _inFlight > 0;
  int get inFlight => _inFlight;

  Future<T> run<T>(Future<T> Function() action) {
    final starter = Completer<T>();
    _inFlight++;
    _tail = _tail.catchError((_) {}).then((_) async {
      try {
        starter.complete(await action());
      } catch (e, st) {
        starter.completeError(e, st);
      } finally {
        _inFlight--;
      }
    });
    return starter.future;
  }
}
