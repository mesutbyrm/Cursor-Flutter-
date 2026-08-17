import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/referral/domain/entities/referral_entities.dart';

void main() {
  group('ReferralStatsEntity', () {
    test('backend değerleri olduğu gibi tutulur — istemci hesaplamaz', () {
      const entity = ReferralStatsEntity(
        referralCode: 'ABC12345',
        shareUrl: 'https://canlifal.com/davet?ref=ABC12345',
        totalEarnings: 25,
        monthEarnings: 25,
        invitedCount: 1,
      );
      expect(entity.totalEarnings, 25);
      expect(entity.referralCode, 'ABC12345');
    });
  });

  group('ReferralLedgerEntryEntity', () {
    test('komisyon tutarı backend alanıdır', () {
      const entry = ReferralLedgerEntryEntity(
        id: '1',
        referredUserId: 'u2',
        sourceType: 'LIVE_GIFT',
        grossJeton: 1000,
        beneficiaryShare: 500,
        referralCommission: 25,
        status: 'PAID',
        createdAt: '2026-08-17T00:00:00.000Z',
      );
      expect(entry.referralCommission, 25);
      expect(entry.beneficiaryShare, 500);
    });
  });
}
