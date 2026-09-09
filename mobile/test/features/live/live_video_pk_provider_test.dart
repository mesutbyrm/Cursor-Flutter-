import 'package:canlifal_social/features/live/presentation/providers/live_video_pk_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveVideoPkState', () {
    test('reads left and right scores from battle map', () {
      const state = LiveVideoPkState(
        battle: {
          'status': 'active',
          'score1': 12,
          'score2': 8,
        },
      );
      expect(state.status, 'active');
      expect(state.leftScore, 12);
      expect(state.rightScore, 8);
    });

    test('copyWith clears battle when requested', () {
      const state = LiveVideoPkState(
        battle: {'status': 'ended'},
        unifiedMatchId: 'pk-1',
      );
      final cleared = state.copyWith(clearBattle: true, clearUnifiedMatchId: true);
      expect(cleared.battle, isNull);
      expect(cleared.unifiedMatchId, isNull);
    });
  });
}
