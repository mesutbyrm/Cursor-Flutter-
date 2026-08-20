import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_tip_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpTallSurface(WidgetTester tester, Widget widget) async {
  await tester.binding.setSurfaceSize(const Size(480, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(widget);
}

void main() {
  group('showPsychicTipSheet', () {
    testWidgets('returns selected tip amount when affordable', (tester) async {
      int? result;

      await _pumpTallSurface(
        tester,
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showPsychicTipSheet(
                    context,
                    psychicName: 'Ayşe',
                    jetonBalance: 200,
                  );
                },
                child: const Text('Aç'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(find.text('💝 Bahşiş Ver'), findsOneWidget);
      expect(find.textContaining('Ayşe falcıya'), findsOneWidget);
      expect(find.textContaining('Jetonunuz: 200'), findsOneWidget);

      await tester.tap(find.text('100'));
      await tester.pumpAndSettle();

      expect(result, 100);
    });

    testWidgets('cancel returns null', (tester) async {
      int? result;

      await _pumpTallSurface(
        tester,
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showPsychicTipSheet(
                    context,
                    psychicName: 'Mehmet',
                    jetonBalance: 500,
                  );
                },
                child: const Text('Aç'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
