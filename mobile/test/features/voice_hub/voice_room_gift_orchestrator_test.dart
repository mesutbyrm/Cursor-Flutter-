import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:canlifal_social/features/voice_hub/presentation/gifts/voice_room_gift_orchestrator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('orchestrator dedupes same canonical gift event id', () {
    final o = VoiceRoomGiftOrchestrator();
    final event = LiveGiftEvent(
      id: 'gh-1',
      giftHistoryId: 'gh-1',
      senderName: 'A',
      receiverName: 'B',
      giftId: 'g1',
      giftName: 'Kalp',
      quantity: 1,
      coinCost: 10,
      timestamp: DateTime.utc(2026, 1, 1),
    );
    expect(o.tryAccept(event), isTrue);
    expect(o.tryAccept(event), isFalse);
  });
}
