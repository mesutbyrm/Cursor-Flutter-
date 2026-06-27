import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ScrollParallaxNotifier throttles small scroll deltas', () {
    final parallax = ScrollParallaxNotifier(threshold: 2);
    var notifications = 0;
    parallax.addListener(() => notifications++);

    parallax.update(0.5);
    expect(notifications, 0);
    expect(parallax.offset, 0);

    parallax.update(2.5);
    expect(notifications, 1);
    expect(parallax.offset, 2.5);

    parallax.update(3.0);
    expect(notifications, 1);
  });

  test('TabIndexListenable notifies only on index change', () {
    final vsync = _TestVSync();
    final controller = TabController(length: 3, vsync: vsync);
    addTearDown(controller.dispose);
    final tabIndex = TabIndexListenable(controller);
    addTearDown(tabIndex.dispose);
    var notifications = 0;
    tabIndex.addListener(() => notifications++);

    controller.index = 1;
    expect(notifications, 1);
    expect(tabIndex.index, 1);

    controller.index = 1;
    expect(notifications, 1);
  });

  testWidgets('FloatingEmojiPaintLayer disabled is lightweight', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FloatingEmojiPaintLayer(enabled: false),
        ),
      ),
    );
    expect(find.byType(FloatingEmojiPaintLayer), findsOneWidget);
    expect(find.byType(SizedBox), findsWidgets);
  });
}

class _TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
