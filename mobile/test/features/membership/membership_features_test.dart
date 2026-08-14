import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/domain/membership_model.dart';
import 'package:canlifal_social/features/membership/domain/membership_package_entity.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';

void main() {
  group('MembershipFeatureHighlightEntity', () {
    test('fromJson title ve subtitle', () {
      final feature = MembershipFeatureHighlightEntity.fromJson({
        'id': 'fal',
        'title': 'İndirimli Fal',
        'subtitle': 'Fal bakımlarında indirim',
      });
      expect(feature.id, 'fal');
      expect(feature.title, 'İndirimli Fal');
      expect(feature.subtitle, 'Fal bakımlarında indirim');
    });
  });

  group('MembershipCatalogEntity features', () {
    test('features[] parse edilir', () {
      final catalog = MembershipCatalogEntity.fromJson({
        'packages': [],
        'currentMembership': 'basic',
        'features': [
          {'id': 'badge', 'title': 'Özel Rozet'},
          {'title': 'Öncelikli Destek', 'description': '7/24'},
        ],
      });
      expect(catalog.features.length, 2);
      expect(catalog.features.first.title, 'Özel Rozet');
      expect(catalog.features.last.subtitle, '7/24');
    });
  });

  group('buildMembershipCatalogHintSubtitle', () {
    test('aktif üyelik katalog ipuçları', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 12,
      );
      const tier = MembershipTierModel(
        id: MembershipTierId.gold,
        title: 'Gold',
        subtitle: 'Test',
        monthlyTokens: 1500,
        monthlyPriceTry: 1000,
        accent: Color(0xFFFFD54F),
        badgeIcon: Icons.star,
        glow: Color(0xFFFFC107),
        durationDays: 45,
        falDiscountPercent: 20,
      );
      final subtitle = buildMembershipCatalogHintSubtitle(
        info: info,
        catalogTier: tier,
      );
      expect(subtitle, contains('12 gün kaldı'));
      expect(subtitle, contains('45 gün'));
      expect(subtitle, contains('%20 fal indirimi'));
    });

    test('süresi dolmuş üyelik', () {
      const info = ProfileMembershipInfo(
        raw: 'premium',
        tier: VipTier.premium,
        daysRemaining: 0,
      );
      final subtitle = buildMembershipCatalogHintSubtitle(info: info);
      expect(subtitle, contains('sona erdi'));
    });
  });

  group('formatMembershipPlanDuration', () {
    test('kalan / toplam gün', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 12,
      );
      const tier = MembershipTierModel(
        id: MembershipTierId.gold,
        title: 'Gold',
        subtitle: 'Test',
        monthlyTokens: 1500,
        monthlyPriceTry: 1000,
        accent: Color(0xFFFFD54F),
        badgeIcon: Icons.star,
        glow: Color(0xFFFFC107),
        durationDays: 45,
      );
      expect(
        formatMembershipPlanDuration(
          info: info,
          catalogTier: tier,
          daysRemaining: 12,
        ),
        '12 / 45 gün',
      );
    });
  });
}
