import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/gifts/domain/gift_video_hold.dart';

void main() {
  test('not initialized → no hold', () {
    expect(
      GiftVideoHold.remaining(
        initialized: false,
        position: Duration.zero,
        duration: const Duration(seconds: 15),
      ),
      isNull,
    );
  });

  test('15 s video at 3 s (backend default) → waits remaining + tail', () {
    expect(
      GiftVideoHold.remaining(
        initialized: true,
        position: const Duration(seconds: 3),
        duration: const Duration(seconds: 15),
      ),
      const Duration(seconds: 12) + GiftVideoHold.tail,
    );
  });

  test('video at end → no hold', () {
    expect(
      GiftVideoHold.remaining(
        initialized: true,
        position: const Duration(milliseconds: 14900),
        duration: const Duration(seconds: 15),
      ),
      isNull,
    );
  });

  test('very long video is capped', () {
    expect(
      GiftVideoHold.remaining(
        initialized: true,
        position: Duration.zero,
        duration: const Duration(minutes: 5),
      ),
      GiftVideoHold.maxHold,
    );
  });
}
