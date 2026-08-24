import 'package:canlifal_social/features/shorts/presentation/utils/shorts_count_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatShortCount', () {
    test('null and invalid return 0', () {
      expect(formatShortCount(null), '0');
      expect(formatShortCount(double.nan), '0');
    });

    test('formats thousands', () {
      expect(formatShortCount(1500), '1.5K');
      expect(formatShortCount(12000), '12K');
    });

    test('formats millions', () {
      expect(formatShortCount(2500000), '2.5M');
    });
  });

  group('safeCount', () {
    test('negative becomes 0', () {
      expect(safeCount(-5), 0);
    });

    test('finite int preserved', () {
      expect(safeCount(42), 42);
    });
  });
}
