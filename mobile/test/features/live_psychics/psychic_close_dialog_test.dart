import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_close_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showPsychicCloseDialog', () {
    testWidgets('confirm returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showPsychicCloseDialog(
                    context,
                    title: 'Seansı Bitir',
                    message: 'Görüşmeyi sonlandırmak istiyor musunuz?',
                    confirmLabel: 'Bitir',
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

      expect(find.text('Seansı Bitir'), findsOneWidget);
      expect(find.text('Görüşmeyi sonlandırmak istiyor musunuz?'), findsOneWidget);

      await tester.tap(find.text('Bitir'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('cancel returns false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showPsychicCloseDialog(
                    context,
                    title: 'Çık',
                    message: 'Bekleme ekranından ayrıl?',
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
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });
  });
}
