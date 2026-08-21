import 'package:canlifal_social/features/fortune/presentation/data/fortune_display_resolver.dart';
import 'package:canlifal_social/features/platform/data/models/fortune_request_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FortuneDisplayResolver API parse', () {
    test('normal request type response', () {
      final entry = FortuneDisplayResolver.entryFromRequestTypeJson({
        'id': 'tarot',
        'name': 'Tarot Falı',
        'description': 'Kart yorumu',
        'jetonCost': 5,
        'icon': 'https://cdn.example.com/tarot.webp',
        'sortOrder': 1,
      });
      expect(entry, isNotNull);
      expect(entry!.slug, 'tarot');
      expect(entry.title, 'Tarot Falı');
      expect(entry.subtitle, 'Kart yorumu');
      expect(entry.jetonCost, 5);
      expect(entry.imageUrl, contains('tarot.webp'));
    });

    test('null price hides cost', () {
      final entry = FortuneDisplayResolver.entryFromRequestTypeJson({
        'slug': 'tarot',
        'name': 'Tarot',
      });
      expect(entry?.jetonCost, isNull);
      expect(entry?.hasPrice, isFalse);
    });

    test('zero price hides cost', () {
      final entry = FortuneDisplayResolver.entryFromRequestTypeJson({
        'slug': 'tarot',
        'name': 'Tarot',
        'price': 0,
      });
      expect(entry?.jetonCost, isNull);
    });

    test('inactive item returns null', () {
      final entry = FortuneDisplayResolver.entryFromRequestTypeJson({
        'slug': 'tarot',
        'name': 'Tarot',
        'isActive': false,
      });
      expect(entry, isNull);
    });

    test('missing description leaves subtitle null', () {
      final entry = FortuneDisplayResolver.entryFromRequestTypeJson({
        'slug': 'kahve-fali',
        'name': 'Kahve Falı',
        'jetonCost': 3,
      });
      expect(entry?.subtitle, isNull);
    });

    test('home card json maps coffee to kahve-fali', () {
      final entry = FortuneDisplayResolver.entryFromHomeCardJson({
        'slug': 'coffee',
        'title': 'Kahve Falı',
        'description': 'Fincan yorumu',
        'priceInTokens': 8,
      });
      expect(entry?.slug, 'kahve-fali');
      expect(entry?.jetonCost, 8);
      expect(entry?.subtitle, 'Fincan yorumu');
    });

    test('preserves API order when sortOrder is zero', () {
      final entries = FortuneDisplayResolver.fromRequestTypes([
        FortuneRequestType(key: 'tarot', label: 'Tarot'),
        FortuneRequestType(key: 'kahve-fali', label: 'Kahve'),
      ]);
      expect(entries.map((e) => e.slug), ['tarot', 'kahve-fali']);
    });

    test('sorts by sortOrder when backend provides it', () {
      final entries = FortuneDisplayResolver.fromRequestTypes([
        FortuneRequestType(key: 'tarot', label: 'Tarot', sortOrder: 2),
        FortuneRequestType(key: 'kahve-fali', label: 'Kahve', sortOrder: 1),
      ]);
      expect(entries.map((e) => e.slug), ['kahve-fali', 'tarot']);
    });

    test('fromCatalog returns 14+ types as last fallback', () {
      final entries = FortuneDisplayResolver.fromCatalog();
      expect(entries.length, greaterThanOrEqualTo(14));
    });

    test('unknown extra fields do not break parse', () {
      final entry = FortuneDisplayResolver.entryFromRequestTypeJson({
        'slug': 'tarot',
        'name': 'Tarot',
        'unknownField': 'ignored',
      });
      expect(entry?.slug, 'tarot');
    });
  });
}
