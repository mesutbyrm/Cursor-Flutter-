import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_video_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PsychicVideoState', () {
    test('timerLabel formats remaining duration', () {
      const state = PsychicVideoState(
        remaining: Duration(minutes: 2, seconds: 5),
        timerStarted: true,
      );

      expect(state.timerLabel, '02:05');
    });

    test('lowTimeWarningPending defaults false', () {
      const state = PsychicVideoState(
        remaining: Duration(minutes: 10),
        timerStarted: true,
      );

      expect(state.lowTimeWarningPending, isFalse);
    });

    test('copyWith clears low-time warning after extend above 120s', () {
      const lowTime = PsychicVideoState(
        remaining: const Duration(seconds: 90),
        timerStarted: true,
        lowTimeWarningPending: true,
      );

      final extended = lowTime.copyWith(
        remaining: const Duration(minutes: 5),
        lowTimeWarningPending: false,
      );

      expect(extended.remaining.inSeconds, 300);
      expect(extended.lowTimeWarningPending, isFalse);
    });

    test('sseFailed flag can be toggled for reconnect banner', () {
      const state = PsychicVideoState(sseFailed: true);
      expect(state.sseFailed, isTrue);

      final recovered = state.copyWith(sseFailed: false);
      expect(recovered.sseFailed, isFalse);
    });
  });
}
