import 'dart:ui';

import 'package:canlifal_social/core/performance/effects_perf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('blurFilter caches identical sigma values', () {
    final a = EffectsPerf.blurFilter(18);
    final b = EffectsPerf.blurFilter(18);
    expect(identical(a, b), isTrue);
  });

  test('blurFilter returns zero filter for non-positive sigma', () {
    final filter = EffectsPerf.blurFilter(0);
    expect(filter, isA<ImageFilter>());
  });

  test('cachedShadow reuses list for same parameters', () {
    final a = EffectsPerf.cachedShadow(
      color: const Color(0xFFB84DFF),
      blurRadius: 16,
    );
    final b = EffectsPerf.cachedShadow(
      color: const Color(0xFFB84DFF),
      blurRadius: 16,
    );
    expect(identical(a, b), isTrue);
  });

  testWidgets('chromeBar wraps child with RepaintBoundary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) => Scaffold(
            body: EffectsPerf.chromeBar(
              context: context,
              sigma: 0,
              child: const Text('bar'),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(RepaintBoundary), findsWidgets);
    expect(find.text('bar'), findsOneWidget);
  });
}
