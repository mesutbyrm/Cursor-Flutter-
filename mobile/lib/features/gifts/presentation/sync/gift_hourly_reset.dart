import 'dart:async';

/// Oda içi jeton / sıralama — her saat başı sıfırlanır.
abstract final class GiftHourlyReset {
  static Duration delayUntilNextHour([DateTime? from]) {
    final now = from ?? DateTime.now();
    final next = DateTime(now.year, now.month, now.day, now.hour).add(
      const Duration(hours: 1),
    );
    return next.difference(now);
  }

  static void scheduleRepeating(
    void Function() onReset, {
    required void Function(void Function() cancel) onCancel,
  }) {
    Timer? timer;
    void arm() {
      timer?.cancel();
      timer = Timer(delayUntilNextHour(), () {
        onReset();
        arm();
      });
    }

    arm();
    onCancel(() => timer?.cancel());
  }
}
