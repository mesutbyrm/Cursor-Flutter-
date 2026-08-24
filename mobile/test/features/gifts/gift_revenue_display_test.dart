import 'package:canlifal_social/features/gifts/domain/gift_revenue_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GiftRevenueDisplay', () {
    test('liveBroadcasterNet — %50 yayıncı payı', () {
      expect(GiftRevenueDisplay.liveBroadcasterNet(100), 50);
      expect(GiftRevenueDisplay.liveBroadcasterNet(99), 50);
      expect(GiftRevenueDisplay.liveBroadcasterNet(0), 0);
    });

    test('estimateVoiceGift — yayıncıya %50 alıcı %50 site', () {
      final owner = GiftRevenueDisplay.estimateVoiceGift(
        gross: 100,
        receiverIsOwner: true,
      );
      expect(owner.receiverNet, 50);
      expect(owner.siteAmount, 50);
      expect(owner.ownerNet, 50);
    });

    test('estimateVoiceGift — misafire %35 alıcı %15 yayıncı %50 site', () {
      final guest = GiftRevenueDisplay.estimateVoiceGift(
        gross: 100,
        receiverIsOwner: false,
      );
      expect(guest.receiverNet, 35);
      expect(guest.ownerNet, 15);
      expect(guest.siteAmount, 50);
    });

    test('publicGross her zaman brüt tutarı döner', () {
      expect(GiftRevenueDisplay.publicGross(100), 100);
      expect(GiftRevenueDisplay.voiceReceiverDisplayGross(100), 100);
    });
  });
}
