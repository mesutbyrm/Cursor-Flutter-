import 'package:canlifal_social/features/fortune/presentation/data/fortune_display_resolver.dart';
import 'package:canlifal_social/features/home/domain/entities/home_fortune_card_entity.dart';
import 'package:canlifal_social/features/platform/data/models/fortune_request_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FortuneDisplayResolver', () {
    test('resolveRouteSlug maps coffee alias to kahve-fali', () {
      expect(
        FortuneDisplayResolver.resolveRouteSlug('coffee'),
        'kahve-fali',
      );
      expect(
        FortuneDisplayResolver.resolveRouteSlug('tarot'),
        'tarot',
      );
    });

    test('fromHomeCards uses API description only', () {
      const cards = [
        HomeFortuneCardEntity(
          id: '1',
          title: 'Kahve Falı',
          slug: 'kahve-fali',
          icon: '☕',
          description: 'API açıklama',
        ),
      ];
      final entries = FortuneDisplayResolver.fromHomeCards(cards);
      expect(entries.first.subtitle, 'API açıklama');
    });

    test('fromHomeCards null description when API omits it', () {
      const cards = [
        HomeFortuneCardEntity(
          id: '1',
          title: 'Tarot',
          slug: 'tarot',
          icon: '🃏',
        ),
      ];
      final entries = FortuneDisplayResolver.fromHomeCards(cards);
      expect(entries.first.subtitle, isNull);
    });

    test('fromHomeCards preserves title image and price', () {
      const cards = [
        HomeFortuneCardEntity(
          id: '1',
          title: 'Kahve Falı',
          slug: 'kahve-fali',
          icon: '☕',
          imageUrl: 'https://cdn.example.com/kahve.webp',
          jetonCost: 5,
        ),
      ];
      final entries = FortuneDisplayResolver.fromHomeCards(cards);
      expect(entries, hasLength(1));
      expect(entries.first.slug, 'kahve-fali');
      expect(entries.first.title, 'Kahve Falı');
      expect(entries.first.jetonCost, 5);
      expect(entries.first.imageUrl, contains('kahve.webp'));
    });

    test('fromRequestTypes filters inactive and sorts by sortOrder', () {
      final types = [
        FortuneRequestType(
          key: 'tarot',
          label: 'Tarot Falı',
          sortOrder: 2,
          jetonCost: 10,
        ),
        FortuneRequestType(
          key: 'kahve-fali',
          label: 'Kahve Falı',
          sortOrder: 1,
          jetonCost: 5,
          isActive: false,
        ),
        FortuneRequestType(
          key: 'el-fali',
          label: 'El Falı',
          sortOrder: 0,
        ),
      ];
      final entries = FortuneDisplayResolver.fromRequestTypes(types);
      expect(entries.map((e) => e.slug), ['el-fali', 'tarot']);
      expect(entries.first.title, 'El Falı');
      expect(entries.last.jetonCost, 10);
    });

    test('fromCatalog returns 14+ non-daily types', () {
      final entries = FortuneDisplayResolver.fromCatalog();
      expect(entries.length, greaterThanOrEqualTo(14));
      expect(entries.any((e) => e.slug == 'kahve-fali'), isTrue);
      expect(entries.any((e) => e.slug == 'tarot'), isTrue);
      expect(entries.any((e) => e.slug == 'ruya-tabiri'), isTrue);
    });

    test('FortuneRequestType.fromJson parses backend fields', () {
      final type = FortuneRequestType.fromJson({
        'id': 'kahve-fali',
        'name': 'Kahve Falı',
        'icon': 'https://cdn.example.com/icon.webp',
        'jetonCost': 7,
        'description': 'Fincan falı',
        'sortOrder': 3,
        'isActive': true,
      });
      expect(type.key, 'kahve-fali');
      expect(type.label, 'Kahve Falı');
      expect(type.jetonCost, 7);
      expect(type.imageUrl, contains('icon.webp'));
      expect(type.description, 'Fincan falı');
      expect(type.sortOrder, 3);
      expect(type.isActive, isTrue);
    });
  });
}
