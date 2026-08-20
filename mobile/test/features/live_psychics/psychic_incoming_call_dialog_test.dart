import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_incoming_call_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_live_psychics_repository.dart';

void main() {
  group('showPsychicIncomingCallDialog', () {
    testWidgets('reject calls respondSession and closes dialog', (tester) async {
      final repo = FakeLivePsychicsRepository(
        respondResult: const PsychicRespondResult(
          success: true,
          roomId: 'room_1',
        ),
      );
      PsychicIncomingDialogClose? close;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            livePsychicsRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    close = await showPsychicIncomingCallDialog(
                      context,
                      ref,
                      sessionId: 'sess_incoming',
                      clientName: 'Mehmet',
                      fortuneType: 'tarot',
                      durationMinutes: 10,
                      totalJeton: 100,
                    );
                  },
                  child: const Text('Göster'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Göster'));
      await tester.pumpAndSettle();

      expect(find.text('Mehmet'), findsOneWidget);
      expect(find.text('Kabul Et'), findsOneWidget);

      await tester.tap(find.text('Reddet'));
      await tester.pumpAndSettle();

      expect(repo.lastRespondAction, 'reject');
      expect(repo.lastRespondSessionId, 'sess_incoming');
      expect(close?.action, PsychicIncomingDialogAction.rejected);
    });

    testWidgets('accept success closes with accepted action', (tester) async {
      final repo = FakeLivePsychicsRepository(
        respondResult: const PsychicRespondResult(
          success: true,
          roomId: 'room_accept',
        ),
      );
      PsychicIncomingDialogClose? close;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            livePsychicsRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    close = await showPsychicIncomingCallDialog(
                      context,
                      ref,
                      sessionId: 'sess_accept',
                      clientName: 'Elif',
                      fortuneType: 'general',
                      durationMinutes: 15,
                      totalJeton: 150,
                    );
                  },
                  child: const Text('Göster'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Göster'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kabul Et'));
      await tester.pumpAndSettle();

      expect(repo.lastRespondAction, 'accept');
      expect(close?.action, PsychicIncomingDialogAction.accepted);
      expect(close?.respond?.roomId, 'room_accept');
    });
  });
}
