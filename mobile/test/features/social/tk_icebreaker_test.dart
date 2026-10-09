import 'package:canlifal_social/features/social/presentation/tanis_kaynas_2026/tk_highlights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('buz kırıcı gün bazlı başlar, Sonraki ile döner', (tester) async {
    final day = DateTime(2026, 1, 3); // yılın 2. günü
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: TkIcebreakerCard(today: day)),
      ),
    );
    const q = TkIcebreakerCard.questions;
    expect(find.text(q[2 % q.length]), findsOneWidget);
    await tester.tap(find.byKey(const Key('tk-icebreaker-next')));
    await tester.pumpAndSettle();
    expect(find.text(q[3 % q.length]), findsOneWidget);
  });
}
