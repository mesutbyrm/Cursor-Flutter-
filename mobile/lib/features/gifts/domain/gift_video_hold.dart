/// Video hediye süresi — backend `durationMs` (varsayılan 3000) veya
/// `gift_finished` olayı videoyu yarıda kesmesin (GIFT-001).
abstract final class GiftVideoHold {
  /// Bitişe bu kadar kala video "bitti" sayılır.
  static const endTolerance = Duration(milliseconds: 250);

  /// Video bittikten sonra sönme payı.
  static const tail = Duration(milliseconds: 300);

  /// Bozuk/sonsuz videoda kuyruğun kilitlenmemesi için üst sınır.
  static const maxHold = Duration(seconds: 60);

  /// Videonun oynaması için gereken kalan süre; bitmişse veya bilinmiyorsa null.
  static Duration? remaining({
    required bool initialized,
    required Duration position,
    required Duration duration,
  }) {
    if (!initialized || duration <= Duration.zero) return null;
    final left = duration - position;
    if (left <= endTolerance) return null;
    final withTail = left + tail;
    return withTail > maxHold ? maxHold : withTail;
  }
}
