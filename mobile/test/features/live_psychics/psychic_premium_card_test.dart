import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_premium_card.dart';

void main() {
  testWidgets('PsychicPremiumCard shows name rating and price from props', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PsychicPremiumCard(
            name: 'Ayşe Falcı',
            avatarUrl: null,
            isOnline: true,
            rating: 4.9,
            reviewCount: 12,
            categoryLabel: 'Kahve • Tarot',
            pricePerMinute: 100,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Ayşe Falcı'), findsOneWidget);
    expect(find.text('Kahve • Tarot'), findsOneWidget);
    expect(find.text('100 jeton/dk'), findsOneWidget);
    expect(find.text('MÜSAİT'), findsOneWidget);
  });

  testWidgets('PsychicPremiumCard hides price when zero', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PsychicPremiumCard(
            name: 'Test',
            avatarUrl: null,
            isOnline: false,
            rating: 0,
            reviewCount: 0,
            categoryLabel: 'Tarot',
            pricePerMinute: 0,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('jeton/dk'), findsNothing);
    expect(find.text('ÇEVRİMDIŞI'), findsOneWidget);
  });
}
