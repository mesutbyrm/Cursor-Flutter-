import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';

void main() {
  group('resolveJetonBalanceAfterOpen', () {
    test('uses explicit balance from open response', () {
      const result = BanaOzelOpenResultEntity(
        content: 'ok',
        itemSlug: 'x',
        itemName: 'X',
        jetonSpent: 2,
        jetonBalance: 8,
      );
      expect(
        resolveJetonBalanceAfterOpen(currentBalance: 10, result: result),
        8,
      );
    });

    test('derives balance when open response omits jetonBalance', () {
      const result = BanaOzelOpenResultEntity(
        content: 'ok',
        itemSlug: 'x',
        itemName: 'X',
        jetonSpent: 3,
        jetonBalance: 0,
      );
      expect(
        resolveJetonBalanceAfterOpen(currentBalance: 10, result: result),
        7,
      );
    });
  });
}
