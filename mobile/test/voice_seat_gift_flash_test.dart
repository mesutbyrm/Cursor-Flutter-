import 'package:canlifal_social/features/live/domain/entities/live_gift_event.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/voice_seat_gift_flash_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceSeatGiftFlashNotifier', () {
    test('receiverKey prefers user id', () {
      expect(
        VoiceSeatGiftFlashNotifier.receiverKey(userId: 'u1', displayName: 'Ali'),
        'id:u1',
      );
    });

    test('max visible is 3', () {
      expect(VoiceSeatGiftFlashNotifier.maxVisible, 3);
    });

    test('ttl is 3 seconds', () {
      expect(VoiceSeatGiftFlashNotifier.ttl, const Duration(seconds: 3));
    });
  });

  test('VoiceSeatGiftFlash expires after ttl', () {
    final flash = VoiceSeatGiftFlash(
      id: '1',
      senderName: 'A',
      receiverKey: 'id:r1',
      giftName: 'Rose',
      quantity: 1,
      jeton: 10,
      expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    expect(flash.expired, isTrue);
  });

  test('LiveGiftEvent jetonAmount used for flash', () {
    final ev = LiveGiftEvent(
      id: 'g1',
      senderName: 'Ali',
      receiverName: 'Veli',
      giftId: 'rose',
      giftName: 'Rose',
      quantity: 2,
      coinCost: 50,
      timestamp: DateTime.now(),
      receiverId: 'r1',
    );
    expect(ev.jetonAmount, 100);
  });

  test('per-receiver cap keeps up to 3 flashes each', () {
    final flashes = <VoiceSeatGiftFlash>[];
    for (var i = 0; i < 5; i++) {
      const key = 'id:a';
      var forReceiver = [...flashes.where((f) => f.receiverKey == key)];
      forReceiver.add(
        VoiceSeatGiftFlash(
          id: 'f$i',
          senderName: 'S',
          receiverKey: key,
          giftName: 'G',
          quantity: 1,
          jeton: 1,
          expiresAt: DateTime.now().add(const Duration(seconds: 3)),
        ),
      );
      while (forReceiver.length > VoiceSeatGiftFlashNotifier.maxVisible) {
        forReceiver.removeAt(0);
      }
      flashes
        ..removeWhere((f) => f.receiverKey == key)
        ..addAll(forReceiver);
    }
    expect(flashes.where((f) => f.receiverKey == 'id:a').length, 3);
  });
}
