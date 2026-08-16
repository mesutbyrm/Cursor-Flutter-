import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/profile/presentation/premium_2026/widgets/profile_premium_card.dart';

void main() {
  group('ProfilePremiumCard', () {
    testWidgets('süresi dolmuş gold yenile CTA', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfilePremiumCard(
              membership: 'gold',
              daysRemaining: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Yenile'), findsOneWidget);
      expect(find.text('Yönet'), findsOneWidget);
    });

    testWidgets('aktif gold ayrıcalıklar CTA', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfilePremiumCard(
              membership: 'gold',
              daysRemaining: 5,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ayrıcalıklar'), findsOneWidget);
    });
  });
}
