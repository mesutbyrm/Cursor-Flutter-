import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_booking_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('showPsychicBookingSheet', () {
    testWidgets('returns selected duration, jeton and fortune type', (tester) async {
      const psychic = PsychicEntity(
        id: 'teller_book',
        name: 'Zeynep',
        isOnline: true,
        pricePerMinute: 10,
        specialties: const ['tarot'],
      );
      PsychicBookingResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showPsychicBookingSheet(
                    context,
                    psychic: psychic,
                    initialMinutes: 10,
                    initialFortuneType: 'tarot',
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

      expect(find.text('Randevu Al'), findsOneWidget);
      expect(find.textContaining('Zeynep'), findsOneWidget);

      await tester.tap(find.text('15 dk'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Falcıya Bağlan'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.minutes, 15);
      expect(result!.jeton, 150);
      expect(result!.fortuneType, 'tarot');
    });

    testWidgets('staff mode shows free session banner', (tester) async {
      const psychic = PsychicEntity(
        id: 'teller_staff',
        name: 'Staff Falcı',
        isOnline: true,
        pricePerMinute: 20,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showPsychicBookingSheet(
                  context,
                  psychic: psychic,
                  isStaff: true,
                ),
                child: const Text('Aç'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(
        find.text('Staff hesabı — seans için jeton düşülmez'),
        findsOneWidget,
      );
      expect(find.text('Ücretsiz'), findsOneWidget);
    });
  });
}
