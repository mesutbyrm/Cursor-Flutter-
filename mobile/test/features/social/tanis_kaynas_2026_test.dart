import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/social/domain/entities/social_discovery_user.dart';
import 'package:canlifal_social/features/social/presentation/tanis_kaynas_2026/tk_common.dart';
import 'package:canlifal_social/features/social/presentation/tanis_kaynas_2026/tk_discovery_card.dart';
import 'package:canlifal_social/features/social/presentation/tanis_kaynas_2026/tk_providers.dart';
import 'package:canlifal_social/features/social/presentation/widgets/discovery_filter_sheet.dart';

SocialDiscoveryUser _user(
  String id, {
  List<String> hobbies = const [],
  List<String> common = const [],
  Object? distance,
  int? match,
  String? lastActive,
}) {
  return SocialDiscoveryUser.fromJson({
    'id': id,
    'name': 'Kullanıcı $id uzun bir isim ile taşma testi',
    'age': 26,
    'city': 'İstanbul',
    'bio': 'Güzel sohbetler, yeni arkadaşlıklar hayatı daha anlamlı kılar. ' * 3,
    'isVerified': true,
    'hobbies': hobbies,
    'commonHobbies': common,
    'matchPercent': ?match,
    'distance': ?distance,
    'lastActive': ?lastActive,
  });
}

void main() {
  group('Keşif verisi', () {
    test('sunucunun {band,text} mesafe nesnesi okunur', () {
      final u = _user('1', distance: {'band': '1-5', 'text': '1-5 km'});
      expect(u.distanceLabel, '1-5 km');
    });

    test('mesafe yoksa etiket boş', () {
      expect(_user('1').distanceLabel, isNull);
    });

    test('görünür deste: işlem yapılan ve ben düşülür, kategori uygulanır', () {
      final users = [
        _user('me'),
        _user('a', common: ['müzik'], match: 50, hobbies: ['müzik']),
        _user('b', distance: {'band': '0-1', 'text': '1 km'}),
        _user('c', common: ['film'], match: 90, hobbies: ['film']),
      ];
      List<String> ids(TkCategory cat, {Set<String> handled = const {}}) =>
          tkVisibleDeck(
            users: users,
            handled: handled,
            filters: const DiscoveryFilterState(),
            category: cat,
            purposes: const {},
            myId: 'me',
          ).map((u) => u.id).toList();

      expect(ids(TkCategory.forYou), ['a', 'b', 'c']);
      expect(ids(TkCategory.forYou, handled: {'a'}), ['b', 'c']);
      expect(ids(TkCategory.nearby), ['b']);
      // İlgi alanları: ortak hobisi olanlar, uyum yüzdesine göre.
      expect(ids(TkCategory.interests), ['c', 'a']);
    });

    test('ilgi amacı (müzik) hobilere göre süzer', () {
      final users = [
        _user('a', hobbies: ['Müzik']),
        _user('b', hobbies: ['Film']),
      ];
      final out = tkVisibleDeck(
        users: users,
        handled: const {},
        filters: const DiscoveryFilterState(),
        category: TkCategory.forYou,
        purposes: const {'music'},
      );
      expect(out.map((u) => u.id), ['a']);
    });

    test('ortak ilgi sayımı gerçek kullanıcılardan', () {
      final counts = tkSharedInterestCounts([
        _user('a', common: ['Müzik', 'Film']),
        _user('b', common: ['müzik']),
        _user('c', hobbies: ['Kahve']),
      ]);
      expect(counts.first.hobby, 'Müzik');
      expect(counts.first.count, 2);
      expect(counts.map((e) => e.hobby), containsAll(['Film', 'Kahve']));
    });
  });

  group('Keşif kartı', () {
    for (final width in [360.0, 390.0, 430.0]) {
      testWidgets('$width px genişlikte taşma yok', (tester) async {
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: TkDiscoveryCard(
                  user: _user(
                    'x',
                    hobbies: [
                      'Müzik',
                      'Film',
                      'Kahve',
                      'Gezi',
                      'Kitap',
                      'Oyun',
                      'Dans',
                    ],
                    match: 92,
                    distance: {'band': '1-5', 'text': '2 km'},
                    lastActive: DateTime.now().toUtc().toIso8601String(),
                  ),
                  onAction: (_) {},
                  onOpenProfile: () {},
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Tanış'), findsOneWidget);
        expect(find.text('%92'), findsOneWidget);
        expect(find.text('+2'), findsOneWidget);
      });
    }

    testWidgets('sağa kaydırma beğen, butonlar eylem gönderir',
        (tester) async {
      final actions = <TkSwipeAction>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TkDiscoveryCard(
                user: _user('x'),
                onAction: actions.add,
                onOpenProfile: () {},
              ),
            ),
          ),
        ),
      );
      await tester.drag(find.byType(TkDiscoveryCard), const Offset(260, 0));
      await tester.pump();
      expect(actions, [TkSwipeAction.like]);

      await tester.tap(find.text('Tanış'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(actions.last, TkSwipeAction.meet);
    });

    testWidgets('boş durum filtre düğmesini gösterir', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TkEmptyState(
              title: 'Henüz sana uygun biri bulunamadı.',
              message: 'Filtrelerini değiştir.',
              actionLabel: 'Filtreleri Düzenle',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Filtreleri Düzenle'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tapped, isTrue);
    });
  });
}
