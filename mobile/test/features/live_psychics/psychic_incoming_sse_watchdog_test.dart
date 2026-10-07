import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live_psychics/data/services/psychic_incoming_sse_service.dart';

void main() {
  group('FORTUNE-003 incoming SSE heartbeat watchdog', () {
    final now = DateTime(2026, 10, 7, 12);

    test('no data yet → not stale', () {
      expect(PsychicIncomingSseService.isStale(null, now), isFalse);
    });

    test('recent heartbeat (15 s) → healthy', () {
      expect(
        PsychicIncomingSseService.isStale(
          now.subtract(const Duration(seconds: 15)),
          now,
        ),
        isFalse,
      );
    });

    test('silent for > 40 s (half-open) → stale', () {
      expect(
        PsychicIncomingSseService.isStale(
          now.subtract(const Duration(seconds: 41)),
          now,
        ),
        isTrue,
      );
    });

    test('threshold matches room SSE (40 s)', () {
      expect(
        PsychicIncomingSseService.heartbeatTimeout,
        const Duration(seconds: 40),
      );
    });
  });
}
