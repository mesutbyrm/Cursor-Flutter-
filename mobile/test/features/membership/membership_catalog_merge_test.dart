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

    test('API popular ve aktif plan birleşir', () {
      const base = MembershipTierModel(
        id: MembershipTierId.gold,
        title: 'Gold',
        subtitle: 'Test',
        monthlyTokens: 1500,
        monthlyPriceTry: 1000,
        accent: Color(0xFFFFC107),
        badgeIcon: Icons.star,
        glow: Color(0xFFFFC107),
      );
      const api = MembershipPackageEntity(
        id: 'gold',
        planId: 'plan-gold',
        title: 'Gold',
        durationDays: 30,
        priceJeton: 2000,
        bonusJeton: 1500,
        falDiscountPercent: 0,
        popular: true,
        isActive: true,
      );
      final merged = mergeMembershipTier(base, api);
      expect(merged.popular, isTrue);
      expect(merged.isActivePlan, isTrue);
      expect(merged.durationDays, 30);
      expect(merged.falDiscountPercent, 0);
    });

    test('API duration ve fal indirimi birleşir', () {
      const base = MembershipTierModel(
        id: MembershipTierId.premium,
        title: 'Premium',
        subtitle: 'Test',
        monthlyTokens: 3500,
        monthlyPriceTry: 1500,
        accent: Color(0xFFA78BFA),
        badgeIcon: Icons.star,
        glow: Color(0xFF8B5CF6),
      );
      const api = MembershipPackageEntity(
        id: 'premium',
        planId: 'plan-premium',
        title: 'Premium',
        durationDays: 45,
        priceJeton: 3000,
        bonusJeton: 3500,
        falDiscountPercent: 15,
      );
      final merged = mergeMembershipTier(base, api);
      expect(merged.durationDays, 45);
      expect(merged.falDiscountPercent, 15);
      expect(merged.durationLabel, '45 gün');
    });

    test('API features[] tier featureHighlights birleşir', () {
      const base = MembershipTierModel(
        id: MembershipTierId.gold,
        title: 'Gold',
        subtitle: 'Test',
        monthlyTokens: 1500,
        monthlyPriceTry: 1000,
        accent: Color(0xFFFFC107),
        badgeIcon: Icons.star,
        glow: Color(0xFFFFC107),
      );
      const api = MembershipPackageEntity(
        id: 'gold',
        planId: 'plan-gold',
        title: 'Gold',
        durationDays: 30,
        priceJeton: 2000,
        bonusJeton: 1500,
        falDiscountPercent: 0,
        features: [
          MembershipFeatureHighlightEntity(
            id: 'vip_rooms',
            title: 'VIP Odalar',
          ),
        ],
      );
      final merged = mergeMembershipTier(base, api);
      expect(merged.featureHighlights.length, 1);
      expect(merged.featureHighlights.first.title, 'VIP Odalar');
    });

    test('API features boşsa base featureHighlights korunur', () {
      const base = MembershipTierModel(
        id: MembershipTierId.gold,
        title: 'Gold',
        subtitle: 'Test',
        monthlyTokens: 1500,
        monthlyPriceTry: 1000,
        accent: Color(0xFFFFC107),
        badgeIcon: Icons.star,
        glow: Color(0xFFFFC107),
        featureHighlights: [
          MembershipFeatureHighlightEntity(id: 'badge', title: 'Rozet'),
        ],
      );
      const api = MembershipPackageEntity(
        id: 'gold',
        planId: 'plan-gold',
        title: 'Gold',
        durationDays: 30,
        priceJeton: 2000,
        bonusJeton: 1500,
        falDiscountPercent: 0,
      );
      final merged = mergeMembershipTier(base, api);
      expect(merged.featureHighlights.length, 1);
      expect(merged.featureHighlights.first.id, 'badge');
    });
  });

  group('mergeMembershipCommonHighlights', () {
    test('katalog ve tier birleşir — id dedupe', () {
      const catalog = [
        MembershipFeatureHighlightEntity(id: 'badge', title: 'Rozet'),
      ];
      const tier = [
        MembershipFeatureHighlightEntity(id: 'badge', title: 'Rozet API'),
        MembershipFeatureHighlightEntity(id: 'vip', title: 'VIP Odalar'),
      ];
      final merged = mergeMembershipCommonHighlights(
        catalogFeatures: catalog,
        tierFeatures: tier,
      );
      expect(merged.length, 2);
      expect(merged.first.title, 'Rozet');
      expect(merged.last.title, 'VIP Odalar');
    });

    test('boş id title ile dedupe', () {
      const catalog = [
        MembershipFeatureHighlightEntity(
          id: '',
          title: 'Öncelikli Destek',
        ),
      ];
      const tier = [
        MembershipFeatureHighlightEntity(
          id: '',
          title: 'Öncelikli Destek',
        ),
        MembershipFeatureHighlightEntity(
          id: 'vip_lounge',
          title: 'VIP Lounge',
        ),
      ];
      final merged = mergeMembershipCommonHighlights(
        catalogFeatures: catalog,
        tierFeatures: tier,
      );
      expect(merged.length, 2);
    });
  });

  group('recommendedTierFromPackages', () {
    test('popular paket tier döner', () {
      const packages = [
        MembershipPackageEntity(
          id: 'premium',
          planId: 'p1',
          title: 'Premium',
          durationDays: 30,
          priceJeton: 3000,
          bonusJeton: 3500,
          falDiscountPercent: 0,
          popular: true,
        ),
      ];
      expect(
        recommendedTierFromPackages(packages),
        MembershipTierId.premium,
      );
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
        durationDays: 45,
      );
      expect(body['requestType'], 'cfc');
      expect(body['packageId'], 'membership_svip');
      expect(body['membershipTier'], 'svip');
      expect(body['amount'], 14000);
      expect(body['packageTitle'], 'SVIP Üyelik · 45 gün');
    });
  });

  group('CurrencyUsageInfo', () {
    test('cfcForTl', () {
      expect(CurrencyUsageInfo.cfcForTl(25), 100);
      expect(CurrencyUsageInfo.cfcForTl(3500), 14000);
    });
  });
}
