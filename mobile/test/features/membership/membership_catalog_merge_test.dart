import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/content/currency_usage_info.dart';
import 'package:canlifal_social/features/membership/domain/membership_catalog_merge.dart';
import 'package:canlifal_social/features/membership/domain/membership_model.dart';
import 'package:canlifal_social/features/membership/domain/membership_package_entity.dart';
import 'package:canlifal_social/features/profile/data/jeton_payment_request.dart';

void main() {
  group('mergeMembershipTier', () {
    test('API fiyat ve jeton birleşir', () {
      const base = MembershipTierModel(
        id: MembershipTierId.svip,
        title: 'SVIP',
        subtitle: 'Test',
        monthlyTokens: 10000,
        monthlyPriceTry: 3500,
        accent: Color(0xFFFF2D7A),
        badgeIcon: Icons.star,
        glow: Color(0xFFB832FF),
      );
      const api = MembershipPackageEntity(
        id: 'svip',
        planId: 'plan-svip-1',
        title: 'SVIP Plus',
        durationDays: 30,
        priceJeton: 6000,
        bonusJeton: 12000,
        falDiscountPercent: 0,
        priceTry: 4000,
      );
      final merged = mergeMembershipTier(base, api);
      expect(merged.title, 'SVIP Plus');
      expect(merged.monthlyTokens, 12000);
      expect(merged.monthlyPriceTry, 4000);
      expect(merged.resolvedPlanId, 'plan-svip-1');
    });
  });

  group('MembershipPackageEntity pricing', () {
    test('resolvedPriceTry priceTry öncelikli', () {
      const pkg = MembershipPackageEntity(
        id: 'gold',
        planId: 'p1',
        title: 'Gold',
        durationDays: 30,
        priceJeton: 2000,
        bonusJeton: 1500,
        falDiscountPercent: 0,
        priceTry: 1200,
      );
      expect(pkg.resolvedPriceTry(0.5), 1200);
      expect(pkg.resolvedPriceJeton(fallbackFromTry: 1000, jetonTlRate: 0.5), 2000);
    });
  });

  group('buildMembershipCfcPaymentRequest', () {
    test('üyelik CFC gövdesi', () {
      final body = buildMembershipCfcPaymentRequest(
        tierId: 'svip',
        tierTitle: 'SVIP',
        cfcAmount: 14000,
        priceTry: 3500,
        method: 'whatsapp',
      );
      expect(body['requestType'], 'cfc');
      expect(body['packageId'], 'membership_svip');
      expect(body['membershipTier'], 'svip');
      expect(body['amount'], 14000);
    });
  });

  group('CurrencyUsageInfo', () {
    test('cfcForTl', () {
      expect(CurrencyUsageInfo.cfcForTl(25), 100);
      expect(CurrencyUsageInfo.cfcForTl(3500), 14000);
    });
  });
}
