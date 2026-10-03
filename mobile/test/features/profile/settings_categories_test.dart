import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/profile/presentation/pages/settings_category_page.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/wallet/domain/wallet_balances.dart';
import 'dart:async';
import 'package:canlifal_social/features/profile/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PendingWallet extends WalletBalancesNotifier {
  @override
  Future<WalletBalances> build() => Completer<WalletBalances>().future;
}

class _NoAuth extends AuthController {
  @override
  Future<UserEntity?> build() async => null;
}

Widget _app(Widget child, {TextDirection dir = TextDirection.ltr, double scale = 1}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => child),
      GoRoute(
        path: '/settings/c/:slug',
        builder: (_, s) => SettingsCategoryPage(slug: s.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/profile/help',
        builder: (_, _) => const Scaffold(body: Text('YARDIM')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_NoAuth.new),
      // Gerçek ağ çağrısı (ve zaman aşımı zamanlayıcısı) başlatma.
      walletBalancesProvider.overrideWith(_PendingWallet.new),
    ],
    child: MaterialApp.router(
      theme: AppTheme.dark(),
      routerConfig: router,
      builder: (context, c) => Directionality(
        textDirection: dir,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
          child: c!,
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  void small(WidgetTester t) {
    t.view.physicalSize = const Size(720, 1280); // 360x640 dp
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
  }

  test('14 kategori, benzersiz slug ve rota', () {
    expect(settingsCategories.length, 14);
    expect(settingsCategories.map((c) => c.slug).toSet().length, 14);
    expect(settingsCategoryBySlug('hesap')?.route, '/settings/c/hesap');
    expect(settingsCategoryBySlug('bildirimler')?.route, '/settings/notifications');
    expect(settingsCategoryBySlug('yok'), isNull);
  });

  testWidgets('Ayarlar: her kategori ayrı kart, küçük ekran + büyük yazı + RTL taşmaz',
      (tester) async {
    small(tester);
    for (final (dir, scale) in [
      (TextDirection.ltr, 1.0),
      (TextDirection.ltr, 1.6),
      (TextDirection.rtl, 1.0),
    ]) {
      await tester.pumpWidget(_app(const SettingsPage(), dir: dir, scale: scale));
      await tester.pumpAndSettle();
      expect(find.text('Hesap'), findsWidgets);
      expect(find.text('Gizlilik ve Güvenlik'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$dir x$scale');
    }
  });

  testWidgets('Kategori kartına dokunmak detay sayfasını açar', (tester) async {
    small(tester);
    await tester.pumpWidget(_app(const SettingsPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Görünüm'));
    await tester.pumpAndSettle();
    expect(find.text('Performans modu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tüm kategori sayfaları taşmadan açılır', (tester) async {
    small(tester);
    for (final slug in ['hesap', 'gizlilik', 'dil', 'gorunum', 'cuzdan', 'canli', 'sesli', 'video', 'veri', 'erisilebilirlik']) {
      await tester.pumpWidget(_app(SettingsCategoryPage(slug: slug), scale: 1.3));
      // Gizlilik sayfası ağ sağlayıcısı beklerken sürekli animasyon çizer.
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: slug);
      // Sayfayı sök ve bekleyen zamanlayıcıları boşalt.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    }
  });
}
