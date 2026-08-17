import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:canlifal_social/core/storage/theme_preferences.dart';
import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/membership/domain/membership_model.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/social/presentation/utils/social_post_location_helper.dart';
import 'package:canlifal_social/features/social/presentation/utils/social_discover_shortcut_labels.dart';
import 'package:canlifal_social/features/social/presentation/utils/social_feed_refresh.dart';
import 'package:canlifal_social/features/social/presentation/utils/social_caption_link_parser.dart';
import 'package:canlifal_social/features/social/presentation/utils/social_post_detail_route.dart';
import 'package:canlifal_social/features/social/presentation/utils/social_user_profile_route.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_music_sync.dart';

/// İstemci tarafı acceptance testleri — 18, 19, 20.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('18 — Müzik sistemi (!istek)', () {
    test('!istek komutu parse edilir', () {
      expect(
        VoiceMusicSync.parseIstekSongTitle('!istek Tarkan - Kış Güneşi'),
        'Tarkan - Kış Güneşi',
      );
    });

    test('SONG_REQUEST_FREE kuyruk satırı tanınır', () {
      expect(
        VoiceMusicSync.isQueueUpdateMessage(
          '[SONG_REQUEST_FREE] abc|Title|||',
        ),
        isTrue,
      );
    });
  });

  group('19 — Tema değiştirme', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ThemePreferences.init();
    });

    test('koyu tema kaydedilir; eski açık/sistem tercihi koyuya taşınır', () async {
      await ThemePreferences.saveThemeMode(ThemeMode.dark);
      expect(ThemePreferences.loadThemeMode(), ThemeMode.dark);

      await ThemePreferences.saveThemeMode(ThemeMode.light);
      expect(ThemePreferences.loadThemeMode(), ThemeMode.dark);

      await ThemePreferences.saveThemeMode(ThemeMode.system);
      expect(ThemePreferences.loadThemeMode(), ThemeMode.dark);
    });

    test('AMOLED bayrağı kalıcıdır', () async {
      await ThemePreferences.saveAmoledDark(true);
      expect(ThemePreferences.loadAmoledDark(), isTrue);
      await ThemePreferences.saveAmoledDark(false);
      expect(ThemePreferences.loadAmoledDark(), isFalse);
    });

    testWidgets('tema modları MaterialApp oluşturur', (tester) async {
      for (final mode in ThemeMode.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            home: const Scaffold(body: Text('tema')),
          ),
        );
        expect(find.text('tema'), findsOneWidget);
      }
    });
  });

  group('20b — Profil üyelik helper sözleşmesi', () {
    test('aktif plan wallet hub alt başlığı', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 7,
      );
      final subtitle = buildMembershipSettingsManageSubtitle(
        info: info,
        tiers: const [],
        daysRemaining: 7,
      );
      expect(subtitle, contains('Gold'));
      expect(subtitle, contains('7'));
    });

    test('süresi dolmuş status pill', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipStatusPillLabel(
          info: info,
          expiresAt: '2020-06-01T00:00:00.000Z',
        ),
        'Gold · 01.06.2020',
      );
    });
  });

  group('20c — Profil üyelik faz 31 helper sözleşmesi', () {
    test('rozet bölümü alt başlığı', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 6,
      );
      final subtitle = buildMembershipBadgesSectionSubtitle(
        info: info,
        unlockedCount: 2,
        totalCount: 6,
      );
      expect(subtitle, contains('2/6'));
      expect(subtitle, contains('Gold'));
    });

    test('VIP Gold hizmet kartı ipucu', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipHubVipGoldServiceCardHint(info: info),
        'Yenile',
      );
    });

    test('cüzdan kazanç teaser ücretsiz', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipWalletEarningsTeaser(info: info),
        contains('Üyelik planları'),
      );
    });
  });

  group('20d — Profil üyelik faz 32 helper sözleşmesi', () {
    test('premium kart alt başlığı aktif plan', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 9,
      );
      final subtitle = buildMembershipPremiumCardSubtitle(
        info: info,
        tiers: const [],
        daysRemaining: 9,
      );
      expect(subtitle, contains('Gold'));
      expect(subtitle, contains('9'));
    });

    test('premium kart CTA süresi dolmuş', () {
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

    test('cüzdan quick link ücretsiz', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(buildMembershipWalletQuickLinkLabel(info: info), 'Üyelik');
    });
  });

  group('20e — Profil üyelik faz 33 helper sözleşmesi', () {
    test('cüzdan kart premium stat', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 2,
      );
      expect(buildMembershipWalletPremiumStatLabel(info: info), 'Gold');
    });

    test('mağaza teaser banner başlığı ücretsiz', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipStoreTeaserBannerTitle(info: info),
        'Üyelik Planları',
      );
    });

    test('cüzdan merkezi süresi dolmuş alt başlık', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipWalletCenterPageSubtitle(info: info),
        contains('Planı yenile'),
      );
    });
  });

  group('20f — Profil üyelik faz 34 helper sözleşmesi', () {
    test('istatistikler alt başlığı ücretsiz', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipAboutStatsSectionSubtitle(info: info),
        contains('yükseltin'),
      );
    });

    test('para çekme aktif üyelik', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 5,
      );
      expect(
        buildMembershipWithdrawalPageSubtitle(info: info),
        contains('Gold üyelik aktif'),
      );
    });

    test('cüzdan store hub süresi dolmuş', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipWalletStoreHubCardSubtitle(
          info: info,
          store: MembershipStoreKind.cfc,
        ),
        contains('planı yenileyin'),
      );
    });
  });

  group('20g — Profil üyelik faz 35 helper sözleşmesi', () {
    test('VIP kısayol chip ücretsiz', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipShortcutsVipChipLabel(info: info),
        'VIP Gold',
      );
    });

    test('aktif banner gold', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 3,
      );
      expect(
        buildMembershipPageActiveBannerText(
          info: info,
          daysRemaining: 3,
        ),
        contains('aktif'),
      );
    });

    test('cüzdan bölümü süresi dolmuş', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipWalletSectionBalanceHint(info: info),
        contains('yenileyin'),
      );
    });
  });

  group('20h — Profil üyelik faz 36 helper sözleşmesi', () {
    test('hizmet kartı ücretsiz başlık', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipHubMembershipServiceCardTitle(info: info),
        'Üyelik Merkezi',
      );
    });

    test('profil düzenleme gold başlık', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 5,
      );
      expect(
        buildMembershipProfileEditSectionTitle(info: info),
        'Gold Üyelik',
      );
    });

    test('üyelik sayfası süresi dolmuş alt başlık', () {
      const info = ProfileMembershipInfo(
        raw: 'gold',
        tier: VipTier.gold,
        daysRemaining: 0,
      );
      expect(
        buildMembershipPageAppBarSubtitle(info: info),
        contains('sona erdi'),
      );
    });
  });

  group('20i — Profil üyelik faz 37 helper sözleşmesi', () {
    test('cüzdan kart premium satır ücretsiz', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipWalletPremiumStatRowLabel(info: info),
        'Premium',
      );
    });

    test('checkout paket başlığı gold', () {
      expect(
        buildMembershipCheckoutPackageTitle(
          tier: const MembershipTierModel(
            id: MembershipTierId.gold,
            title: 'Gold',
            subtitle: 'Test',
            monthlyTokens: 1500,
            monthlyPriceTry: 1000,
            accent: Color(0xFFFFD54F),
            badgeIcon: Icons.star,
            glow: Color(0xFFFFC107),
          ),
        ),
        contains('Gold Üyelik'),
      );
    });

    test('mağaza teaser CTA ücretsiz', () {
      const info = ProfileMembershipInfo(
        raw: 'basic',
        tier: VipTier.basic,
      );
      expect(
        buildMembershipStoreTeaserBannerActionLabel(info: info),
        contains('Planları Gör'),
      );
    });
  });

  group('20j — Profil üyelik faz 38 helper sözleşmesi', () {
    test('rozet bölümü başlık', () {
      expect(buildMembershipBadgesSectionTitle(), 'Üyelik Rozetleri');
    });

    test('istatistik plan satır etiketi', () {
      expect(buildMembershipAboutStatsPlanRowLabel(), 'Üyelik Planı');
    });

    test('CFC ödeme varsayılan not', () {
      expect(
        buildMembershipCfcPaymentRequestDefaultNotes(
          tierTitle: 'Diamond',
          method: 'whatsapp',
        ),
        contains('Diamond'),
      );
    });
  });

  group('20k — Profil üyelik faz 39 helper sözleşmesi', () {
    test('paket kartı uzat etiketi', () {
      expect(buildMembershipPackageCardExtendActionLabel(), 'Uzat');
    });

    test('paket kartı aktif alt metin', () {
      expect(
        buildMembershipPackageCardActiveSubtitle(
          tierTitle: 'Premium',
          daysRemaining: 7,
        ),
        contains('7 gün'),
      );
    });

    test('kozmetik satır etiketi', () {
      expect(
        buildMembershipSettingsCosmeticsRowLabel(),
        'Premium Profil',
      );
    });

    test('cüzdan merkezi jeton mağazası başlığı', () {
      expect(
        buildMembershipWalletCenterJetonStoreTitle(),
        'Jeton Mağazası',
      );
    });
  });

  group('20l — Profil üyelik faz 40 helper sözleşmesi', () {
    test('hizmetler bölüm başlığı', () {
      expect(buildMembershipHubServicesSectionTitle(), 'Hizmetlerim');
    });

    test('jeton yükle aksiyon etiketi', () {
      expect(buildMembershipWalletJetonTopUpActionLabel(), 'Jeton Yükle');
    });

    test('jeton satın alma sayfası başlığı', () {
      expect(buildMembershipJetonPurchasePageTitle(), 'Jeton Satın Al');
    });

    test('platform katılım satır etiketi', () {
      expect(
        buildMembershipAboutStatsPlatformJoinRowLabel(
          formattedDate: '1 Ocak 2026',
        ),
        contains('Üyelik:'),
      );
    });
  });

  group('20m — Sosyal bölüm faz 3 helper sözleşmesi', () {
    test('konum snippet pin emoji', () {
      expect(
        formatSocialPostLocationSnippet('İstanbul'),
        '📍 İstanbul',
      );
    });

    test('konum sonucu ok bayrağı', () {
      const ok = SocialPostLocationResult(label: 'Ankara');
      const fail = SocialPostLocationResult(errorMessage: 'izin yok');
      expect(ok.ok, isTrue);
      expect(fail.ok, isFalse);
    });
  });

  group('20n — Sosyal bölüm faz 4 helper sözleşmesi', () {
    test('keşif kısayolu etiketleri', () {
      expect(socialDiscoverShortcutLabels, hasLength(4));
      expect(socialDiscoverShortcutLabels.first, 'Ünlüler');
      expect(socialDiscoverShortcutLabels.last, 'Sesli');
    });

    test('keşif kısayolu rotaları', () {
      expect(socialDiscoverShortcutRoutes, contains('/live'));
      expect(socialDiscoverShortcutRoutes, contains('/fan-club-hub'));
    });
  });

  group('20o — Sosyal bölüm faz 5 helper sözleşmesi', () {
    test('gömülü oda şeridi başlığı canlı + sesli', () {
      expect(
        buildSocialActiveRoomsEmbeddedTitle(hasLive: true, hasVoice: true),
        'Canlı yayın ve sesli odalar',
      );
    });

    test('gömülü oda şeridi başlığı yalnızca canlı', () {
      expect(
        buildSocialActiveRoomsEmbeddedTitle(hasLive: true, hasVoice: false),
        'Canlı yayınlar',
      );
    });
  });

  group('20p — Sosyal bölüm faz 6 helper sözleşmesi', () {
    test('paylaşım metni bağlantı içerir', () {
      final text = buildSocialPostShareText(
        postId: 'abc',
        caption: 'Merhaba',
      );
      expect(text, contains('Merhaba'));
      expect(text, contains('post=abc'));
    });

    test('hashtag token ayrıştırma', () {
      final tokens = parseSocialCaptionTokens('#canlifal');
      expect(tokens.single.kind, SocialCaptionTokenKind.hashtag);
      expect(tokens.single.value, 'canlifal');
    });
  });

  group('20q — Sosyal bölüm faz 7 helper sözleşmesi', () {
    test('kullanıcı profil rotası', () {
      expect(buildSocialUserProfileRoute('abc'), '/user/abc');
    });
  });

  group('20r — Sosyal bölüm faz 8 helper sözleşmesi', () {
    test('gönderi detay rotası', () {
      expect(buildSocialPostDetailRoute('abc'), '/social/post/abc');
    });
  });

  group('20 — Uygulama performans testi', () {
    setUp(AppTheme.clearCacheForTest);

    test('tema fabrikası 50 çağrı < 2 sn', () {
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 50; i++) {
        AppTheme.light();
        AppTheme.dark();
        AppTheme.amoled();
      }
      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(2000),
        reason: 'Tema oluşturma çok yavaş',
      );
    });
  });
}
