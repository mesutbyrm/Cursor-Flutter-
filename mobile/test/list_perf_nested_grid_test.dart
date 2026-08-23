import 'package:canlifal_social/core/performance/list_perf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListPerf.nestedGridHeight', () {
    test('returns zero for empty grid', () {
      expect(
        ListPerf.nestedGridHeight(
          itemCount: 0,
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
          crossAxisExtent: 300,
        ),
        0,
      );
    });

    test('computes height for two rows', () {
      const width = 300.0;
      const spacing = 10.0;
      const aspect = 1.55;
      final cellW = (width - spacing) / 2;
      final cellH = cellW / aspect;
      final expected = cellH * 2 + spacing;

      expect(
        ListPerf.nestedGridHeight(
          itemCount: 4,
          crossAxisCount: 2,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: aspect,
          crossAxisExtent: width,
        ),
        closeTo(expected, 0.01),
      );
    });
  });
}
