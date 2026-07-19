import 'package:canlifal_social/features/gifts/domain/gift_revenue_display.dart';
import 'package:canlifal_social/features/gifts/domain/session_gift_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SessionGiftSummary formatJetonWithTl', () {
    const s = SessionGiftSummary(
      title: 'Test',
      totalGrossJeton: 100,
      myNetJeton: 50,
      guestNetJeton: 30,
      senders: [
        SessionGiftSenderRow(displayName: 'Ali', grossJeton: 100),
      ],
      jetonTlRate: 0.5,
    );
    expect(s.formatJetonWithTl(100), '100 jeton (50.00 ₺)');
    expect(s.tlForJeton(50), 25);
    expect(s.hasData, isTrue);
  });

  test('voice guest split — alıcı net yayıncı payından ayrı', () {
    final r = GiftRevenueDisplay.estimateVoiceGift(
      gross: 100,
      receiverIsOwner: false,
    );
    expect(r.receiverNet, 35);
    expect(r.ownerNet, 15);
    expect(r.siteAmount, 50);
  });
}
