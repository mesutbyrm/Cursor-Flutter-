import 'package:canlifal_social/features/fortune/presentation/widgets/ultra_premium/fortune_ready_reading_premium_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FortuneReadyReadingPremiumCard renders title and body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FortuneReadyReadingPremiumCard(
            slug: 'tarot',
            title: 'Tarot Hazır Yorumu',
            body: 'Kartların mesajı',
            accent: const Color(0xFFB832FF),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Tarot Hazır Yorumu'), findsOneWidget);
    expect(find.text('Kartların mesajı'), findsOneWidget);
  });
}
