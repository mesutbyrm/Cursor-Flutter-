import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/gifts/domain/gift_engine_parser.dart';
import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';

void main() {
  test('parser uses backend engineDurationMs for video gifts', () {
    final event = LiveGiftEvent(
      id: 'g1',
      giftId: 'rose',
      giftName: 'Gül',
      senderName: 'Ali',
      receiverName: 'Ayşe',
      quantity: 1,
      coinCost: 10,
      timestamp: DateTime.utc(2026, 8, 3),
      engineDurationMs: 6500,
      engineAnimationType: 'mp4',
      videoUrl: 'https://cdn.example.com/gift.mp4',
    );

    final config = GiftEngineParser.fromEvent(event);
    expect(config.durationMs, 6500);
  });

  test('parser extends video play time to actual video length in overlay math', () {
    final event = LiveGiftEvent(
      id: 'g2',
      giftId: 'car',
      giftName: 'Araba',
      senderName: 'Ali',
      receiverName: 'Ayşe',
      quantity: 1,
      coinCost: 100,
      timestamp: DateTime.utc(2026, 8, 3),
      engineDurationMs: 12000,
      engineAnimationType: 'mp4',
    );
    final config = GiftEngineParser.fromEvent(event);
    expect(config.durationMs, 12000);
  });
}
