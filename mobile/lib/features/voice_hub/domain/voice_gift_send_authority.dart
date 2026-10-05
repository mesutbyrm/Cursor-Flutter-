import '../../../core/util/json_util.dart';
import '../../live/domain/entities/live_gift_event.dart';
import 'entities/voice_gift_revenue.dart';

/// Backend otoriteli jeton düşüşü — istemci fiyat×adet hesaplamaz.
abstract final class VoiceGiftSendAuthority {
  static int? resolveSpentJeton({
    required Map<String, dynamic> body,
    VoiceGiftRevenueBreakdown? revenue,
    LiveGiftEvent? giftEvent,
    int? fieldApiSpent,
  }) {
    if (revenue != null && revenue.total > 0) {
      return revenue.total;
    }

    final unwrapped = body['data'] is Map
        ? Map<String, dynamic>.from(body['data'] as Map)
        : body;

    final direct = asInt(
      pick(unwrapped, [
        'totalJeton',
        'totalJetonSpent',
        'jetonAmount',
        'amount',
        'spentAmount',
        'coinCost',
        'totalCoin',
        'totalCost',
        'totalPrice',
        'price',
      ]),
    );
    if (direct != null && direct > 0) return direct;

    if (giftEvent != null) {
      if (giftEvent.totalCoin > 0) return giftEvent.totalCoin;
      final fromEvent = giftEvent.jetonAmount;
      if (fromEvent > 0) return fromEvent;
    }

    if (fieldApiSpent != null && fieldApiSpent > 0) return fieldApiSpent;

    return direct;
  }
}
