import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/pk/data/pk_models.dart';
import 'package:canlifal_social/features/pk/domain/pk_rematch.dart';
import 'package:canlifal_social/features/pk/presentation/widgets/pk_result_overlay.dart';

void main() {
  const finished = PkBattle(
    id: 'battle-1',
    status: PkStatus.completed,
    room1Id: 'room-a',
    room2Id: 'room-b',
    user1Id: 'user-a',
    user2Id: 'user-b',
    score1: 30,
    score2: 12,
    winnerId: 'user-a',
  );

  group('resolvePkRematchTarget', () {
    test('picks the other side when I am room1', () {
      final target =
          resolvePkRematchTarget(battle: finished, myContextId: 'room-a');
      expect(target?.contextId, 'room-b');
      expect(target?.userId, 'user-b');
    });

    test('picks the other side when I am room2', () {
      final target =
          resolvePkRematchTarget(battle: finished, myContextId: 'room-b');
      expect(target?.contextId, 'room-a');
      expect(target?.userId, 'user-a');
    });

    test('ignores surrounding whitespace on my key', () {
      final target =
          resolvePkRematchTarget(battle: finished, myContextId: '  room-a  ');
      expect(target?.contextId, 'room-b');
    });

    test('returns null when my key matches neither side', () {
      expect(
        resolvePkRematchTarget(battle: finished, myContextId: 'room-z'),
        isNull,
      );
    });

    test('returns null when the server sent no room ids', () {
      const battle = PkBattle(id: 'b', status: PkStatus.completed);
      expect(
        resolvePkRematchTarget(battle: battle, myContextId: 'room-a'),
        isNull,
      );
    });

    test('returns null for an empty context key', () {
      expect(
        resolvePkRematchTarget(battle: finished, myContextId: '   '),
        isNull,
      );
    });
  });

  group('PkResultOverlay', () {
    Future<void> pump(
      WidgetTester tester, {
      VoidCallback? onRematch,
      VoidCallback? onDismiss,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: PkResultOverlay(
            battle: finished,
            winnerName: 'Ayşe',
            onRematch: onRematch,
            onDismiss: onDismiss,
          ),
        ),
      );
    }

    testWidgets('shows the winner and score', (tester) async {
      await pump(tester);
      expect(find.text('Ayşe kazandı!'), findsOneWidget);
      expect(find.text('30 — 12'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('offers a rematch only when a target was resolved',
        (tester) async {
      await pump(tester);
      expect(find.text('Rövanş iste'), findsNothing);
      expect(find.text('Kapat'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));

      await pump(tester, onRematch: () {});
      expect(find.text('Rövanş iste'), findsOneWidget);
      expect(find.text('Yayına dön'), findsOneWidget);
      await tester.pump(const Duration(seconds: 16));
    });

    testWidgets('rematch fires onRematch and not onDismiss', (tester) async {
      var rematch = 0;
      var dismiss = 0;
      await pump(
        tester,
        onRematch: () => rematch++,
        onDismiss: () => dismiss++,
      );

      await tester.tap(find.text('Rövanş iste'));
      await tester.pump();

      expect(rematch, 1);
      expect(dismiss, 0);
    });

    testWidgets('closing clears the finished battle', (tester) async {
      var dismiss = 0;
      await pump(tester, onRematch: () {}, onDismiss: () => dismiss++);

      await tester.tap(find.text('Yayına dön'));
      await tester.pump();

      expect(dismiss, 1);
    });

    testWidgets('timing out also clears the finished battle', (tester) async {
      var dismiss = 0;
      await pump(tester, onDismiss: () => dismiss++);

      await tester.pump(const Duration(seconds: 6));

      expect(dismiss, 1);
    });

    testWidgets('a decision fires exactly once', (tester) async {
      var rematch = 0;
      var dismiss = 0;
      await pump(
        tester,
        onRematch: () => rematch++,
        onDismiss: () => dismiss++,
      );

      await tester.tap(find.text('Rövanş iste'));
      await tester.pump();
      // Süre dolsa bile ikinci karar üretilmemeli.
      await tester.pump(const Duration(seconds: 20));

      expect(rematch, 1);
      expect(dismiss, 0);
    });
  });
}
