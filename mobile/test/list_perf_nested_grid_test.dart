import 'package:canlifal_social/core/performance/list_perf.dart';
import 'package:flutter/material.dart';
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

  group('ListPerf.nestedGridHeightForDelegate', () {
    test('handles fixed cross axis count delegate', () {
      const width = 300.0;
      const spacing = 10.0;
      final cellW = (width - spacing) / 2;
      final expected = cellW * 2 + spacing;

      expect(
        ListPerf.nestedGridHeightForDelegate(
          itemCount: 4,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: 1,
          ),
          crossAxisExtent: width,
        ),
        closeTo(expected, 0.01),
      );
    });
  });

  group('ListPerf.nestedListHeight', () {
    test('returns zero for empty list', () {
      expect(
        ListPerf.nestedListHeight(itemCount: 0, itemExtent: 40),
        0,
      );
    });

    test('computes height with separators', () {
      expect(
        ListPerf.nestedListHeight(
          itemCount: 3,
          itemExtent: 40,
          separatorExtent: 8,
        ),
        136,
      );
    });
  });
}
