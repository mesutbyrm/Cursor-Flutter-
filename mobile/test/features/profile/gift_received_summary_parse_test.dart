import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/profile/domain/entities/profile_stats_entity.dart';

void main() {
  group('GiftReceivedSummaryEntity.tryParseList', () {
    test('parses summary list from GET /api/user/received-gifts', () {
      final items = GiftReceivedSummaryEntity.tryParseList({
        'summary': [
          {'name': 'Gül', 'icon': '🌹', 'count': 3, 'coins': 12},
        ],
      });
      expect(items, isNotNull);
      expect(items, hasLength(1));
      expect(items!.first.name, 'Gül');
      expect(items.first.icon, '🌹');
      expect(items.first.count, 3);
      expect(items.first.coins, 12);
    });

    test('parses nested data.gifts and empty list as success', () {
      final nested = GiftReceivedSummaryEntity.tryParseList({
        'data': {
          'gifts': [
            {'giftName': 'Kalp', 'iconUrl': 'https://cdn/heart.png', 'quantity': 2},
          ],
        },
      });
      expect(nested, isNotNull);
      expect(nested!.first.name, 'Kalp');
      expect(nested.first.count, 2);

      final empty = GiftReceivedSummaryEntity.tryParseList({'items': <Object>[]});
      expect(empty, isNotNull);
      expect(empty, isEmpty);
    });

    test('returns null when body has no list (caller should try fallback path)', () {
      expect(GiftReceivedSummaryEntity.tryParseList(null), isNull);
      expect(GiftReceivedSummaryEntity.tryParseList('oops'), isNull);
      expect(GiftReceivedSummaryEntity.tryParseList({'error': 'fail'}), isNull);
    });
  });
}
