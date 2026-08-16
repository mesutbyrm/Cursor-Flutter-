import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:canlifal_social/core/storage/theme_preferences.dart';
import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
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
