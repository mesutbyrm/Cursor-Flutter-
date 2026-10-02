import 'package:canlifal_social/features/live/presentation/widgets/premium_2026/live/live_floating_hearts_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(int token) => MaterialApp(
      home: Scaffold(
        body: LiveFloatingHeartsOverlay(burstToken: token),
      ),
    );

void main() {
  testWidgets('kalpler doğar, ömrü bitince temizlenir ve ticker durur', (t) async {
    await t.pumpWidget(_host(0));
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);

    await t.pumpWidget(_host(3)); // +3 kalp
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byIcon(Icons.favorite_rounded), findsWidgets);

    // En uzun ömür ~3.3 sn + 0.2 sn gecikme.
    await t.pump(const Duration(seconds: 4));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    // Ticker durduysa bekleyen kare kalmaz.
    expect(t.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('arka arkaya patlamada en fazla 30 kalp tutulur', (t) async {
    await t.pumpWidget(_host(0));
    for (var i = 1; i <= 12; i++) {
      await t.pumpWidget(_host(i * 5));
      await t.pump(const Duration(milliseconds: 20));
    }
    expect(
      find.byIcon(Icons.favorite_rounded).evaluate().length,
      lessThanOrEqualTo(30),
    );
    await t.pump(const Duration(seconds: 5));
  });
}
