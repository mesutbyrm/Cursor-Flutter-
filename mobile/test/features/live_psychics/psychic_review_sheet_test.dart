import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_review_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_live_psychics_repository.dart';

void main() {
  group('showPsychicReviewSheet', () {
    testWidgets('submits rating and comment via repository', (tester) async {
      final repo = FakeLivePsychicsRepository();
      bool? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            livePsychicsRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await showPsychicReviewSheet(
                      context,
                      sessionId: 'sess_review',
                      tellerId: 'teller_review',
                      tellerName: 'Ayşe',
                    );
                  },
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ayşe ile seansınızı'), findsOneWidget);

      await tester.tap(find.byType(IconButton).at(2));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Harika bir seanstı',
      );
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(repo.lastReviewSessionId, 'sess_review');
      expect(repo.lastReviewTellerId, 'teller_review');
      expect(repo.lastReviewRating, 3);
      expect(repo.lastReviewComment, 'Harika bir seanstı');
      expect(find.text('Değerlendirmeniz kaydedildi'), findsOneWidget);
    });

    testWidgets('dismiss with Şimdi değil returns false', (tester) async {
      final repo = FakeLivePsychicsRepository();
      bool? result;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            livePsychicsRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await showPsychicReviewSheet(
                      context,
                      sessionId: 'sess_skip',
                      tellerId: 'teller_skip',
                      tellerName: 'Mehmet',
                    );
                  },
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Şimdi değil'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(repo.lastReviewSessionId, isNull);
    });

    testWidgets('shows API error when review POST fails', (tester) async {
      final repo = FakeLivePsychicsRepository(
        submitReviewError: const ApiException('Değerlendirme kaydedilemedi'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            livePsychicsRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showPsychicReviewSheet(
                      context,
                      sessionId: 'sess_fail',
                      tellerId: 'teller_fail',
                      tellerName: 'Ayşe',
                    );
                  },
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gönder'));
      await tester.pumpAndSettle();

      expect(find.text('Değerlendirme kaydedilemedi'), findsOneWidget);
      expect(find.text('Değerlendirmeniz kaydedildi'), findsNothing);
    });
  });
}
