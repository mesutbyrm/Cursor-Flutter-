import 'package:canlifal_social/features/fortune/presentation/widgets/premium_2026/fortune_premium_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FortunePremiumCard shows title and price from props', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FortunePremiumCard(
            slug: 'kahve-fali',
            title: 'Kahve Falı',
            accent: const Color(0xFFB832FF),
            jetonCost: 10,
            emoji: '☕',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Kahve Falı'), findsOneWidget);
    expect(find.text('10 Jeton'), findsOneWidget);
  });

  testWidgets('FortunePremiumCard hides price when null', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FortunePremiumCard(
            slug: 'tarot',
            title: 'Tarot',
            accent: const Color(0xFFB832FF),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Jeton'), findsNothing);
  });
}
