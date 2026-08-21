import 'package:canlifal_social/core/util/fortune_price_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseFortuneJetonPrice', () {
    test('parses jetonCost', () {
      expect(parseFortuneJetonPrice({'jetonCost': 5}), 5);
    });

    test('parses priceInTokens and credits', () {
      expect(parseFortuneJetonPrice({'priceInTokens': 10}), 10);
      expect(parseFortuneJetonPrice({'credits': 7}), 7);
    });

    test('returns null for zero price', () {
      expect(parseFortuneJetonPrice({'jetonCost': 0}), isNull);
    });

    test('returns null for missing price', () {
      expect(parseFortuneJetonPrice({}), isNull);
    });
  });
}
