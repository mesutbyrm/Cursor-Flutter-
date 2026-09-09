import 'package:canlifal_social/features/notifications/domain/notification_event_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seedFromHistory blocks historical popups', () {
    final gate = NotificationEventGate();
    gate.markSessionStart();
    gate.seedFromHistory(['a', 'b']);

    expect(
      gate.shouldShowHistoricalPopup(
        eventId: 'a',
        isRead: false,
        createdAt: DateTime.now(),
      ),
      isFalse,
    );
  });

  test('shouldProcessRealtime allows once per session', () {
    final gate = NotificationEventGate();
    gate.markSessionStart();

    expect(gate.shouldProcessRealtime('evt-1'), isTrue);
    expect(gate.shouldProcessRealtime('evt-1'), isFalse);
    expect(gate.shouldProcessRealtime('evt-2'), isTrue);
  });

  test('historical popup rejects read and pre-session items', () {
    final gate = NotificationEventGate();
    final started = DateTime.utc(2026, 9, 9, 12, 0);
    gate.markSessionStart();
    // Simulate session started at "now" — created before session should skip
    expect(
      gate.shouldShowHistoricalPopup(
        eventId: 'old',
        isRead: false,
        createdAt: started.subtract(const Duration(hours: 1)),
      ),
      isFalse,
    );
    expect(
      gate.shouldShowHistoricalPopup(
        eventId: 'read',
        isRead: true,
        createdAt: DateTime.now(),
      ),
      isFalse,
    );
  });
}
