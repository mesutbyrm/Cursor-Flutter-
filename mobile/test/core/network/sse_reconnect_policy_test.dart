import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/network/sse/sse_reconnect_policy.dart';

void main() {
  group('SseReconnectPolicy', () {
    test('never gives up so a room stream survives a long outage', () {
      for (final attempt in [1, 5, 20, 21, 100, 5000]) {
        expect(
          SseReconnectPolicy.shouldGiveUp(attempt),
          isFalse,
          reason: 'attempt $attempt abandoned the stream permanently',
        );
      }
    });

    test('early attempts reconnect fast', () {
      expect(SseReconnectPolicy.delayForAttempt(1).inSeconds, 0);
      expect(SseReconnectPolicy.delayForAttempt(2).inSeconds, 0);
      expect(SseReconnectPolicy.delayForAttempt(3).inSeconds, 1);
    });

    test('backoff grows past the table instead of hammering every 5s', () {
      final sixth = SseReconnectPolicy.delayForAttempt(6);
      final seventh = SseReconnectPolicy.delayForAttempt(7);
      final eighth = SseReconnectPolicy.delayForAttempt(8);

      expect(sixth.inSeconds, greaterThanOrEqualTo(5));
      expect(seventh.inSeconds, greaterThan(sixth.inSeconds));
      expect(eighth.inSeconds, greaterThan(seventh.inSeconds));
    });

    test('delay is capped at maxDelay including jitter headroom', () {
      for (final attempt in [10, 50, 1000]) {
        final delay = SseReconnectPolicy.delayForAttempt(attempt);
        expect(
          delay.inMilliseconds,
          lessThanOrEqualTo(
            (SseReconnectPolicy.maxDelay.inMilliseconds * 1.1).round(),
          ),
          reason: 'attempt $attempt exceeded the cap',
        );
      }
    });
  });
}
