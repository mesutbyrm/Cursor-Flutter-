import 'package:canlifal_social/features/games/domain/game_move_dedupe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameMoveDedupe', () {
    test('extractEventId reads moveId and version', () {
      expect(
        GameMoveDedupe.extractEventId({'moveId': 'm-42'}),
        'moveId:m-42',
      );
      expect(
        GameMoveDedupe.extractEventId({'version': 7}),
        'version:7',
      );
    });

    test('shouldApplySnapshot rejects duplicate event ids', () {
      final seen = <String>{};
      final raw = {'moveId': 'same-move'};

      expect(
        GameMoveDedupe.shouldApplySnapshot(raw: raw, seenEventIds: seen),
        isTrue,
      );
      expect(
        GameMoveDedupe.shouldApplySnapshot(raw: raw, seenEventIds: seen),
        isFalse,
      );
      expect(seen.length, 1);
    });

    test('shouldApplySnapshot accepts snapshots without event id', () {
      final seen = <String>{};
      expect(
        GameMoveDedupe.shouldApplySnapshot(raw: const {}, seenEventIds: seen),
        isTrue,
      );
      expect(
        GameMoveDedupe.shouldApplySnapshot(raw: const {}, seenEventIds: seen),
        isTrue,
      );
    });
  });
}
