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

  group('buildMembershipPremiumCardTitle', () {
    test('aktif ücretli', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 5,
      );
      expect(buildMembershipPremiumCardTitle(info: info), 'Gold Üyelik');
    });

    test('süresi dolmuş', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipPremiumCardTitle(
          info: info,
          expiresAt: '2020-05-10T00:00:00.000Z',
        ),
        'Gold · 10.05.2020',
      );
    });
  });

  group('buildMembershipHubSectionTitle', () {
    test('ücretsiz planlar', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(buildMembershipHubSectionTitle(info: info), 'Üyelik Planları');
    });

    test('aktif gold', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 3,
      );
      expect(buildMembershipHubSectionTitle(info: info), 'Gold Üyelik');
    });
  });

  group('buildGrowthHubMembershipTitle', () {
    test('ücretsiz küçük harf', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(buildGrowthHubMembershipTitle(info: info), 'Üyelik planları');
    });

    test('aktif gold üyeliği', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 3,
      );
      expect(buildGrowthHubMembershipTitle(info: info), 'Gold üyeliği');
    });
  });

  group('buildMembershipHubActionLabel', () {
    test('süresi dolmuş yenile', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(buildMembershipHubActionLabel(info: info), 'Yenile');
    });

    test('ücretsiz özel etiket', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipHubActionLabel(info: info, freeLabel: 'Yükselt'),
        'Yükselt',
      );
    });
  });

  group('buildMembershipWalletSubscriptionStatLabel', () {
    test('ücretsiz tire', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(buildMembershipWalletSubscriptionStatLabel(info: info), '—');
    });

    test('süresi dolmuş tier ve tarih', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipWalletSubscriptionStatLabel(
          info: info,
          expiresAt: '2020-05-10T00:00:00.000Z',
        ),
        'Gold · 10.05.2020',
      );
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

  group('resolveMembershipTierCardBadge', () {
    const goldTier = MembershipTierModel(
      id: MembershipTierId.gold,
      title: 'Gold',
      subtitle: 'Test',
      monthlyTokens: 1500,
      monthlyPriceTry: 1000,
      accent: Color(0xFFFFD54F),
      badgeIcon: Icons.star,
      glow: Color(0xFFFFC107),
    );

    const premiumTier = MembershipTierModel(
      id: MembershipTierId.premium,
      title: 'Premium',
      subtitle: 'Test',
      monthlyTokens: 3500,
      monthlyPriceTry: 1500,
      accent: Color(0xFFA78BFA),
      badgeIcon: Icons.star,
      glow: Color(0xFF8B5CF6),
    );

    test('aktif üyelik eşleşen tier — Aktif', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 10,
      );
      expect(
        resolveMembershipTierCardBadge(tier: goldTier, info: info),
        MembershipTierCardBadge.active,
      );
    });

    test('süresi dolmuş eşleşen tier — Süresi doldu', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        resolveMembershipTierCardBadge(tier: goldTier, info: info),
        MembershipTierCardBadge.expired,
      );
    });

    test('tier.popular — Popüler', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      const popularTier = MembershipTierModel(
        id: MembershipTierId.premium,
        title: 'Premium',
        subtitle: 'Test',
        monthlyTokens: 3500,
        monthlyPriceTry: 1500,
        accent: Color(0xFFA78BFA),
        badgeIcon: Icons.star,
        glow: Color(0xFF8B5CF6),
        popular: true,
      );
      expect(
        resolveMembershipTierCardBadge(tier: popularTier, info: info),
        MembershipTierCardBadge.popular,
      );
    });

    test('API recommended paket — Popüler', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
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
        resolveMembershipTierCardBadge(
          tier: premiumTier,
          info: info,
          packages: packages,
        ),
        MembershipTierCardBadge.popular,
      );
    });

    test('ücretsiz kullanıcı — rozet yok', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        resolveMembershipTierCardBadge(tier: goldTier, info: info),
        MembershipTierCardBadge.none,
      );
    });
  });

  group('buildMembershipHubVipPillLabel', () {
    test('aktif gold — tier etiketi', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 10,
      );
      expect(
        buildMembershipHubVipPillLabel(info: info),
        '💎 Gold',
      );
    });

    test('süresi dolmuş — saat emojisi', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipHubVipPillLabel(
          info: info,
          membershipExpiresAt: '2020-01-15T00:00:00.000Z',
        ),
        '⏳ Gold · 15.01.2020',
      );
    });

    test('ücretsiz — null', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(buildMembershipHubVipPillLabel(info: info), isNull);
    });
  });

  group('buildMembershipWalletHubSubtitle', () {
    test('aktif üyelik plan süresi', () {
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
      final subtitle = buildMembershipWalletHubSubtitle(
        info: info,
        tiers: const [tier],
        catalogTier: tier,
        daysRemaining: 12,
      );
      expect(subtitle, contains('Gold'));
      expect(subtitle, contains('12'));
    });

    test('ücretsiz teaser', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      final subtitle = buildMembershipWalletHubSubtitle(
        info: info,
        tiers: const [],
      );
      expect(subtitle, contains('Gold, Diamond'));
    });
  });

  group('buildMembershipStoreTeaserSubtitle', () {
    test('jeton mağaza ücretsiz', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      final subtitle = buildMembershipStoreTeaserSubtitle(
        info: info,
        store: MembershipStoreKind.jeton,
        tiers: const [],
      );
      expect(subtitle, contains('jeton yüklerken'));
    });

    test('cfc mağaza aktif üyelik', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 5,
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
        falDiscountPercent: 15,
      );
      final subtitle = buildMembershipStoreTeaserSubtitle(
        info: info,
        store: MembershipStoreKind.cfc,
        tiers: const [tier],
        catalogTier: tier,
      );
      expect(subtitle, contains('Gold üyeliği aktif'));
      expect(subtitle, contains('%15 fal'));
      expect(subtitle, contains('CFC'));
    });
  });

  group('buildMembershipSettingsManageSubtitle', () {
    test('aktif üyelik wallet hub ile aynı', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 5,
      );
      final subtitle = buildMembershipSettingsManageSubtitle(
        info: info,
        tiers: const [],
        daysRemaining: 5,
      );
      expect(subtitle, contains('Gold'));
      expect(subtitle, contains('5'));
    });
  });

  group('buildMembershipAboutStatsPlanValue', () {
    test('süresi dolmuş expired label', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipAboutStatsPlanValue(
          info: info,
          expiresAt: '2020-03-10T00:00:00.000Z',
        ),
        'Gold · 10.03.2020',
      );
    });

    test('ücretsiz standart', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(buildMembershipAboutStatsPlanValue(info: info), 'Standart');
    });
  });

  group('buildMembershipStatusPillLabel', () {
    test('süresi dolmuş pill', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipStatusPillLabel(
          info: info,
          expiresAt: '2020-01-01T00:00:00.000Z',
        ),
        'Gold · 01.01.2020',
      );
    });

    test('aktif gold tier', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 3,
      );
      expect(buildMembershipStatusPillLabel(info: info), 'Gold');
    });

    test('ücretsiz null', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(buildMembershipStatusPillLabel(info: info), isNull);
    });
  });

  group('buildMembershipWalletActiveBannerText', () {
    test('aktif gold banner', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 10,
      );
      final text = buildMembershipWalletActiveBannerText(
        info: info,
        daysRemaining: 10,
      );
      expect(text, contains('Gold üyesiniz'));
      expect(text, contains('10'));
    });
  });

  group('shouldShowMembershipWalletActiveBanner', () {
    test('aktif gün varsa true', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 3,
      );
      expect(
        shouldShowMembershipWalletActiveBanner(info: info, daysRemaining: 3),
        isTrue,
      );
    });
  });

  group('buildMembershipHubServiceCardHint', () {
    test('ücretsiz teaser kısaltma', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipHubServiceCardHint(info: info, tiers: const []),
        'Planlar',
      );
    });

    test('süresi dolmuş yenile', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipHubServiceCardHint(info: info, tiers: const []),
        'Yenile',
      );
    });
  });

  group('buildMembershipQuickMenuLabel', () {
    test('aktif gold tier etiketi', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 5,
      );
      expect(buildMembershipQuickMenuLabel(info: info), 'Gold');
    });

    test('süresi dolmuş yenile', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(buildMembershipQuickMenuLabel(info: info), 'Yenile');
    });
  });

  group('buildMembershipCheckoutFooterHint', () {
    const goldTier = MembershipTierModel(
      id: MembershipTierId.gold,
      title: 'Gold',
      subtitle: 'Test',
      monthlyTokens: 1500,
      monthlyPriceTry: 1000,
      accent: Color(0xFFFFD54F),
      badgeIcon: Icons.star,
      glow: Color(0xFFFFC107),
      falDiscountPercent: 10,
    );

    test('seçili plan özeti', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      final hint = buildMembershipCheckoutFooterHint(
        info: info,
        selectedTier: goldTier,
      );
      expect(hint, contains('Gold'));
      expect(hint, contains('%10 fal'));
    });

    test('aktif eşleşen plan', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 8,
      );
      final hint = buildMembershipCheckoutFooterHint(
        info: info,
        selectedTier: goldTier,
      );
      expect(hint, contains('Aktif planınız'));
    });
  });

  group('buildMembershipBadgesSectionSubtitle', () {
    test('aktif gold rozet oranı', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 5,
      );
      expect(
        buildMembershipBadgesSectionSubtitle(
          info: info,
          unlockedCount: 3,
          totalCount: 8,
        ),
        '3/8 rozet açık · Gold',
      );
    });

    test('süresi dolmuş yenile', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipBadgesSectionSubtitle(
          info: info,
          unlockedCount: 1,
          totalCount: 5,
        ),
        contains('planı yenileyin'),
      );
    });
  });

  group('buildMembershipHubVipGoldServiceCardHint', () {
    test('aktif vip', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 3,
      );
      expect(
        buildMembershipHubVipGoldServiceCardHint(info: info),
        'Aktif',
      );
    });

    test('ücretsiz odalar', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipHubVipGoldServiceCardHint(info: info),
        'Odalar',
      );
    });
  });

  group('buildMembershipWalletEarningsTeaser', () {
    test('ücretsiz teaser', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipWalletEarningsTeaser(info: info),
        contains('fal indirimi'),
      );
    });

    test('aktif indirimli plan', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 4,
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
        falDiscountPercent: 12,
      );
      expect(
        buildMembershipWalletEarningsTeaser(
          info: info,
          catalogTier: tier,
        ),
        contains('%12 fal'),
      );
    });
  });

  group('buildMembershipPremiumCardSubtitle', () {
    test('aktif gold wallet hub ile aynı', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 6,
      );
      final subtitle = buildMembershipPremiumCardSubtitle(
        info: info,
        tiers: const [],
        daysRemaining: 6,
      );
      expect(subtitle, contains('Gold'));
      expect(subtitle, contains('6'));
    });
  });

  group('buildMembershipPremiumCardPrimaryActionLabel', () {
    test('aktif ayrıcalıklar', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 3,
      );
      expect(
        buildMembershipPremiumCardPrimaryActionLabel(info: info),
        'Ayrıcalıklar',
      );
    });

    test('süresi dolmuş yenile', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipPremiumCardPrimaryActionLabel(info: info),
        'Yenile',
      );
    });
  });

  group('buildMembershipVipBannerTitle', () {
    test('ücretsiz üyelik planları', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(buildMembershipVipBannerTitle(info: info), 'Üyelik Planları');
    });
  });

  group('buildMembershipVipBannerActionLabel', () {
    test('ücretsiz planları gör', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipVipBannerActionLabel(info: info),
        'Planları Gör >',
      );
    });
  });

  group('buildMembershipWalletQuickLinkLabel', () {
    test('aktif gold tier', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 4,
      );
      expect(buildMembershipWalletQuickLinkLabel(info: info), 'Gold');
    });

    test('süresi dolmuş yenile', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(buildMembershipWalletQuickLinkLabel(info: info), 'Yenile');
    });
  });

  group('buildMembershipWalletPremiumStatLabel', () {
    test('aktif gold tier', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 3,
      );
      expect(buildMembershipWalletPremiumStatLabel(info: info), 'Gold');
    });

    test('ücretsiz standart', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(buildMembershipWalletPremiumStatLabel(info: info), 'Standart');
    });
  });

  group('buildMembershipWalletSubscriptionsTileLabel', () {
    test('süresi dolmuş yenile', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipWalletSubscriptionsTileLabel(info: info),
        'Yenile',
      );
    });

    test('ücretsiz planlar', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipWalletSubscriptionsTileLabel(info: info),
        'Planlar',
      );
    });
  });

  group('buildMembershipShortcutsPlanChipLabel', () {
    test('aktif gold planı yönet', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 5,
      );
      expect(
        buildMembershipShortcutsPlanChipLabel(info: info),
        'Planı Yönet',
      );
    });
  });

  group('buildMembershipStoreTeaserBannerTitle', () {
    test('ücretsiz üyelik planları', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipStoreTeaserBannerTitle(info: info),
        'Üyelik Planları',
      );
    });
  });

  group('buildMembershipWalletCenterPageSubtitle', () {
    test('aktif gold üyelik', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 4,
      );
      expect(
        buildMembershipWalletCenterPageSubtitle(info: info),
        'Jeton · CFC · Gold üyelik',
      );
    });

    test('ücretsiz premium', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipWalletCenterPageSubtitle(info: info),
        contains('Premium üyelik'),
      );
    });
  });
}
