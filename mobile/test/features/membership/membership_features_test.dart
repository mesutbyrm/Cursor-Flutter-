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

    test('süresi dolmuş üyelik bitiş tarihi', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      final subtitle = buildMembershipCatalogHintSubtitle(
        info: info,
        expiresAt: '2020-05-10T00:00:00.000Z',
      );
      expect(subtitle, contains('10.05.2020'));
      expect(subtitle, contains('sona erdi'));
    });
  });

  group('buildMembershipExpiredPlanLabel', () {
    test('bitiş tarihi ile', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipExpiredPlanLabel(
          info: info,
          expiresAt: '2020-05-10T00:00:00.000Z',
        ),
        'Gold · 10.05.2020',
      );
    });

    test('tarih yoksa süresi doldu', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipExpiredPlanLabel(info: info),
        'Gold · süresi doldu',
      );
    });
  });

  group('buildMembershipExpiredBannerText', () {
    test('bitiş tarihi ile banner', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      final text = buildMembershipExpiredBannerText(
        info: info,
        expiresAt: '2020-05-10T00:00:00.000Z',
      );
      expect(text, contains('Gold'));
      expect(text, contains('10.05.2020'));
    });
  });

  group('buildMembershipPageExpiredBannerText', () {
    test('planı yenile eki', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      final text = buildMembershipPageExpiredBannerText(info: info);
      expect(text, contains('planı yenile'));
      expect(text, contains('sona erdi'));
    });
  });

  group('buildFreeUserMembershipTeaserSubtitle', () {
    test('popular API paket tier ipucu', () {
      const tiers = [
        MembershipTierModel(
          id: MembershipTierId.gold,
          title: 'Gold',
          subtitle: 'Test',
          monthlyTokens: 1500,
          monthlyPriceTry: 1000,
          accent: Color(0xFFFFD54F),
          badgeIcon: Icons.star,
          glow: Color(0xFFFFC107),
          durationDays: 45,
          falDiscountPercent: 15,
        ),
      ];
      const packages = [
        MembershipPackageEntity(
          id: 'gold',
          planId: 'plan-gold',
          title: 'Gold',
          durationDays: 45,
          priceJeton: 2000,
          bonusJeton: 1500,
          falDiscountPercent: 15,
          popular: true,
        ),
      ];
      final subtitle = buildFreeUserMembershipTeaserSubtitle(
        tiers: tiers,
        packages: packages,
      );
      expect(subtitle, contains('Gold öne çıkan'));
      expect(subtitle, contains('45 gün'));
      expect(subtitle, contains('%15 fal indirimi'));
    });
  });

  group('buildVipGoldShortcutSubtitle', () {
    test('aktif VIP', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 5,
      );
      expect(
        buildVipGoldShortcutSubtitle(info),
        'Gold · VIP odalar aktif',
      );
    });

    test('ücretsiz kullanıcı', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildVipGoldShortcutSubtitle(info),
        'Gold ve üzeri planlarda',
      );
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

    test('gün yoksa ISO bitiş tarihi', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
      );
      expect(
        formatMembershipPlanDuration(
          info: info,
          expiresAt: '2030-06-15T12:00:00.000Z',
        ),
        'Bitiş: 15.06.2030',
      );
    });
  });

  group('buildMembershipCatalogHintSubtitle expiresAt', () {
    test('aktif üyelik gün yok — bitiş tarihi', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
      );
      final subtitle = buildMembershipCatalogHintSubtitle(
        info: info,
        expiresAt: '2030-01-20T00:00:00.000Z',
      );
      expect(subtitle, contains('Bitiş: 20.01.2030'));
    });
  });

  group('buildGrowthHubMembershipSubtitle', () {
    test('aktif üyelik görev bonusu', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 5,
      );
      final subtitle = buildGrowthHubMembershipSubtitle(info: info);
      expect(subtitle, contains('5 gün'));
      expect(subtitle, contains('görev bonusları aktif'));
    });
  });

  group('membership banner expiry labels', () {
    test('aktif banner gün yoksa bitiş tarihi', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
      );
      final label = formatMembershipPlanDuration(
        info: info,
        expiresAt: '2030-03-20T00:00:00.000Z',
      );
      expect(label, 'Bitiş: 20.03.2030');
    });

    test('süresi dolmuş banner bitiş etiketi', () {
      expect(
        formatMembershipExpiryLabel('2020-05-10T00:00:00.000Z'),
        '10.05.2020',
      );
    });
  });
}
