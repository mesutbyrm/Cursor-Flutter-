import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/gifts/domain/gift_system_message.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';

void main() {
  test('GiftSystemMessage format matches spec', () {
    final event = LiveGiftEvent(
      id: 'g1',
      giftId: 'rose',
      giftName: 'Rose',
      senderName: 'Mesut',
      receiverName: 'Ayşe',
      quantity: 1,
      coinCost: 100,
      timestamp: DateTime(2026, 1, 1),
    );
    expect(
      GiftSystemMessage.format(event),
      "Mesut, Ayşe'ye 100 Jeton değerinde Rose gönderdi.",
    );
  });
}
