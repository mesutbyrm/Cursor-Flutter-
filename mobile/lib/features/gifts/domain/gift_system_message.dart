import '../../live/domain/entities/live_gift_event.dart';

/// Hediye sistem mesajı — sohbet ve kayan duyuru metni.
abstract final class GiftSystemMessage {
  /// Örnek: «Mesut, Ayşe'ye 100 Jeton değerinde Rose gönderdi.»
  static String format(LiveGiftEvent event) {
    final sender =
        event.senderName.trim().isNotEmpty ? event.senderName.trim() : 'Biri';
    final receiver = event.receiverName.trim().isNotEmpty
        ? event.receiverName.trim()
        : 'kullanıcı';
    final gift = event.giftName.trim().isNotEmpty
        ? event.giftName.trim()
        : 'hediye';
    final jeton = event.jetonAmount;
    return "$sender, $receiver'ye $jeton Jeton değerinde $gift gönderdi.";
  }
}
