import 'package:canlifal_social/core/economy/domain/economy_wallet_snapshot.dart';
import 'package:canlifal_social/core/economy/presentation/providers/economy_providers.dart';
import 'package:canlifal_social/core/network/cookie_jar_provider.dart';
import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';
import 'package:canlifal_social/features/bana_ozel/presentation/providers/bana_ozel_providers.dart';
import 'package:canlifal_social/features/fortune/domain/entities/fortune_display_entry.dart';
import 'package:canlifal_social/features/fortune/domain/entities/user_fortune_entity.dart';
import 'package:canlifal_social/features/fortune/presentation/pages/fortune_tarot_hub_page.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_api_providers.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_birth_profile_provider.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_hub_providers.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_types_display_provider.dart';
import 'package:canlifal_social/features/fortune/presentation/widgets/fortune_hub_2026/fortune_hub_sections.dart';
import 'package:canlifal_social/features/home/domain/entities/home_trend_video_entity.dart';
import 'package:canlifal_social/features/home/presentation/providers/home_providers.dart';
import 'package:canlifal_social/features/inbox/presentation/providers/inbox_unread_providers.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth extends AuthController {
  @override
  Future<UserEntity?> build() async => const UserEntity(
        id: 'u1',
        username: 'u',
        displayName: 'Kullanıcı',
      );
}

class _History extends FortuneHistoryNotifier {
  @override
  Future<List<UserFortuneEntity>> build() async => [
        UserFortuneEntity(
          id: '1',
          type: 'Tarot',
          slug: 'tarot',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        UserFortuneEntity(
          id: '2',
          type: 'Kahve Falı',
          slug: 'kahve-fali',
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
      ];
}

class _HistoryError extends FortuneHistoryNotifier {
  @override
  Future<List<UserFortuneEntity>> build() async => throw Exception('x');
}

class _Catalog extends BanaOzelCatalogNotifier {
  @override
  Future<BanaOzelCatalogEntity> build() async => const BanaOzelCatalogEntity(
        items: [
          BanaOzelItemEntity(
            id: '1',
            slug: 'kisisel-oneri',
            nameTr: 'Kişisel Fal Önerisi',
            descTr: 'Sana özel hazırlandı',
            icon: '🔮',
            jetonCost: 5,
            category: 'tarot',
          ),
        ],
      );
}

class _EmptyCatalog extends BanaOzelCatalogNotifier {
  @override
  Future<BanaOzelCatalogEntity> build() async =>
      const BanaOzelCatalogEntity(items: []);
}

List<Override> _overrides({
  bool filled = true,
  bool historyError = false,
}) =>
    [
      cookieJarProvider.overrideWithValue(PersistCookieJar()),
      authControllerProvider.overrideWith(_FakeAuth.new),
      economyWalletProvider.overrideWith(
        (ref) async => const EconomyWalletSnapshot(cfc: 100, jeton: 50),
      ),
      inboxUnreadCountProvider.overrideWith((ref) => 2),
      fortuneHistoryProvider.overrideWith(
        historyError ? _HistoryError.new : _History.new,
      ),
      fortuneBirthProfileProvider.overrideWith((ref) async => null),
      fortuneDailyInsightsProvider.overrideWith(
        (ref) async => FortuneDailyInsights.fallback(),
      ),
      homeFortuneCardsProvider.overrideWith((ref) async => []),
      homeFortuneRequestTypesProvider.overrideWith((ref) async => []),
      homeTrendVideosProvider.overrideWith(
        (ref) async => filled
            ? const [
                HomeTrendVideoEntity(
                  id: 'v1',
                  title: 'Kahve falı',
                  channelName: 'k',
                  viewCount: 12400,
                  likesCount: 1280,
                ),
              ]
            : <HomeTrendVideoEntity>[],
      ),
      homeOnlinePsychicsProvider.overrideWith(
        (ref) async => filled
            ? const [
                PsychicEntity(
                  id: 'p1',
                  name: 'İlhamperisi',
                  isOnline: true,
                  rating: 5,
                  pricePerMinute: 100,
                  specialties: ['Kahve'],
                ),
              ]
            : <PsychicEntity>[],
      ),
      fortuneTypesDisplayProvider.overrideWith(
        (ref) async => const [
          FortuneDisplayEntry(slug: 'tarot', title: 'Tarot'),
          FortuneDisplayEntry(slug: 'kahve-fali', title: 'Kahve Falı'),
          FortuneDisplayEntry(slug: 'el-fali', title: 'El Falı'),
        ],
      ),
      banaOzelCatalogProvider.overrideWith(
        filled ? _Catalog.new : _EmptyCatalog.new,
      ),
    ];

Future<void> _pumpHub(
  WidgetTester tester, {
  required Size size,
  double textScale = 1,
  List<Override>? overrides,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides ?? _overrides(),
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: const FortuneTarotHubPage(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _done(WidgetTester t) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 2));
}

Finder _hubScrollable() => find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    300,
    scrollable: _hubScrollable(),
  );
  await tester.pump();
}

Future<void> _scrollAll(WidgetTester tester) async {
  final list = _hubScrollable();
  for (var i = 0; i < 14; i++) {
    await tester.drag(list, const Offset(0, -420));
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final c in <({String name, Size size, double scale})>[
    (name: '320x640', size: const Size(320, 640), scale: 1),
    (name: '360x800', size: const Size(360, 800), scale: 1),
    (name: '430x932', size: const Size(430, 932), scale: 1),
    (name: '360x800 yazı %160', size: const Size(360, 800), scale: 1.6),
    (name: 'yatay 800x360', size: const Size(800, 360), scale: 1),
  ]) {
    testWidgets('hub taşma/istisna olmadan çizilir: ${c.name}', (tester) async {
      final errors = <Object>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) {
        errors.add(d.exception);
        prev?.call(d);
      };
      addTearDown(() => FlutterError.onError = prev);

      await _pumpHub(tester, size: c.size, textScale: c.scale);
      await _scrollAll(tester);

      expect(errors, isEmpty, reason: errors.join('\n'));
      await _done(tester);
    });
  }

  testWidgets('gerçek verili bölümler görünür', (tester) async {
    await _pumpHub(tester, size: const Size(390, 844));
    expect(find.text('Fal & Tarot'), findsOneWidget);
    expect(find.textContaining('Kaderin'), findsOneWidget);
    expect(find.text('Falına Bak'), findsOneWidget);
    expect(find.text('2 fal kaydın var'), findsOneWidget);
    expect(find.text('Enerjin'), findsOneWidget);
    expect(find.text('Ay Evresi'), findsOneWidget);

    await _scrollTo(tester, find.text('İlhamperisi'));
    expect(find.text('İlhamperisi'), findsOneWidget);
    expect(find.text('MÜSAİT'), findsOneWidget);
    await _done(tester);
  });

  testWidgets('arama tüm türler listesini süzer', (tester) async {
    await _pumpHub(tester, size: const Size(390, 844));
    await tester.enterText(find.byType(TextField), 'el f');
    await tester.pump();
    final list = _hubScrollable();
    await tester.scrollUntilVisible(
      find.text('TÜM FAL TÜRLERİ'),
      300,
      scrollable: list,
    );
    expect(find.text('El Falı'), findsWidgets);
    expect(find.text('Aramana uygun fal türü bulunamadı'), findsNothing);

    await tester.scrollUntilVisible(
      find.byType(TextField),
      -300,
      scrollable: list,
    );
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Aramana uygun fal türü bulunamadı'),
      300,
      scrollable: list,
    );
    expect(find.text('Aramana uygun fal türü bulunamadı'), findsOneWidget);
    await _done(tester);
  });

  testWidgets('boş ve hata durumları düzgün gösterilir', (tester) async {
    await _pumpHub(
      tester,
      size: const Size(390, 844),
      overrides: _overrides(filled: false, historyError: true),
    );
    expect(find.text('Fal kayıtların şu an alınamadı'), findsOneWidget);
    for (final text in [
      'Son fallar yüklenemedi',
      'Şu anda müsait falcı bulunmuyor. Biraz sonra tekrar deneyin.',
      'Henüz kısa video yok',
      'Size özel yeni içerikler hazırlanıyor.',
    ]) {
      await _scrollTo(tester, find.text(text));
      expect(find.text(text), findsOneWidget);
    }
    await _done(tester);
  });

  test('fortuneRelativeDate', () {
    final now = DateTime(2026, 10, 1, 12);
    expect(fortuneRelativeDate(null, now: now), '');
    expect(
      fortuneRelativeDate(now.subtract(const Duration(days: 2)), now: now),
      '2 gün önce',
    );
    expect(
      fortuneRelativeDate(now.subtract(const Duration(days: 8)), now: now),
      '1 hafta önce',
    );
    expect(
      fortuneRelativeDate(now.subtract(const Duration(days: 1)), now: now),
      'Dün',
    );
  });
}
