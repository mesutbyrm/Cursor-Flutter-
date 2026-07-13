import 'package:canlifal_social/features/gifts/domain/gift_revenue_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GiftRevenueDisplay', () {
    test('liveBroadcasterNet — %50 yayıncı payı', () {
      expect(GiftRevenueDisplay.liveBroadcasterNet(100), 50);
      expect(GiftRevenueDisplay.liveBroadcasterNet(99), 50);
      expect(GiftRevenueDisplay.liveBroadcasterNet(0), 0);
    });

    test('estimateVoiceGift — %50 alıcı %50 site', () {
      final r = GiftRevenueDisplay.estimateVoiceGift(
        gross: 100,
        receiverIsOwner: false,
      );
      expect(r.receiverNet, 50);
      expect(r.siteAmount, 50);
      expect(r.ownerNet, 0);

      final owner = GiftRevenueDisplay.estimateVoiceGift(
        gross: 200,
        receiverIsOwner: true,
      );
      expect(owner.receiverNet, 100);
      expect(owner.siteAmount, 100);
      expect(owner.ownerNet, 0);
    });
  });
}
