import 'package:flutter/foundation.dart';

/// Üst üste binen overlay önceliği (düşük sayı = üstte).
enum CdsOverlayKind {
  decorative(100),
  vipEntrance(80),
  giftFullscreen(60),
  pkCelebration(50),
  modal(40),
  payment(30),
  critical(10);

  const CdsOverlayKind(this.priority);
  final int priority;
}

/// Tek aktif tam ekran hediye görseli — çakışmayı önler.
class CdsFullscreenGiftGate extends ChangeNotifier {
  CdsFullscreenGiftGate._();
  static final instance = CdsFullscreenGiftGate._();

  String? _activeEventId;
  DateTime? _acquiredAt;

  /// En uzun hediye 30 sn; bırakılmayan (ör. ekran kapanırken dispose
  /// edilemeyen) kilit bundan sonra geçersiz sayılır. Aksi halde bazı
  /// cihazlarda tek bir takılı hediye sonraki TÜM hediyeleri gizliyordu.
  static const staleAfter = Duration(seconds: 35);

  bool get _stale {
    final at = _acquiredAt;
    return at != null && DateTime.now().difference(at) > staleAfter;
  }

  bool tryAcquire(String eventId) {
    if (_activeEventId != null && _activeEventId != eventId && !_stale) {
      return false;
    }
    _activeEventId = eventId;
    _acquiredAt = DateTime.now();
    return true;
  }

  void release(String eventId) {
    if (_activeEventId == eventId) {
      _activeEventId = null;
      _acquiredAt = null;
      notifyListeners();
    }
  }

  bool isBlocked(String eventId) =>
      _activeEventId != null && _activeEventId != eventId && !_stale;
}
