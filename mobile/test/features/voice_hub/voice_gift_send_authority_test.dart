import 'package:canlifal_social/features/voice_hub/domain/entities/voice_gift_revenue.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_gift_send_authority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prefers revenue.total from backend', () {
    const revenue = VoiceGiftRevenueBreakdown(
      total: 500,
      roomType: 'NORMAL',
      receiverNet: 400,
      ownerNet: 50,
      siteAmount: 50,
    );
    final spent = VoiceGiftSendAuthority.resolveSpentJeton(
      body: const {'spentAmount': 0},
      revenue: revenue,
    );
    expect(spent, 500);
  });

  test('reads totalJeton from live gift send body', () {
    final spent = VoiceGiftSendAuthority.resolveSpentJeton(
      body: const {'totalJeton': 500, 'quantity': 1},
    );
    expect(spent, 500);
  });
}
