import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_extend_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showPsychicExtendSheet', () {
    testWidgets('returns selected option when balance is sufficient', (tester) async {
      PsychicExtendOption? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showPsychicExtendSheet(
                    context,
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Süre Ekle'), findsOneWidget);
      expect(find.textContaining('Jetonunuz: 200'), findsOneWidget);

      await tester.tap(find.text('10 dakika'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.minutes, 10);
      expect(result!.jeton, 100);
    });

    testWidgets('staff exempt can select without jeton balance', (tester) async {
      PsychicExtendOption? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showPsychicExtendSheet(
                    context,
                    jetonBalance: 0,
                    staffExempt: true,
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

      expect(
        find.text('Staff hesabı — uzatma için jeton düşülmez'),
        findsOneWidget,
      );

      await tester.tap(find.text('30 dakika'));
      await tester.pumpAndSettle();

      expect(result?.minutes, 30);
      expect(result?.jeton, 300);
    });

    testWidgets('cancel returns null', (tester) async {
      PsychicExtendOption? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showPsychicExtendSheet(
                    context,
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
