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

  bool tryAcquire(String eventId) {
    if (_activeEventId != null && _activeEventId != eventId) {
      return false;
    }
    _activeEventId = eventId;
    return true;
  }

  void release(String eventId) {
    if (_activeEventId == eventId) {
      _activeEventId = null;
      notifyListeners();
    }
  }

  bool isBlocked(String eventId) =>
      _activeEventId != null && _activeEventId != eventId;
}
