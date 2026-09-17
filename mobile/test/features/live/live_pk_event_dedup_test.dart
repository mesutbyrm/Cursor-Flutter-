import 'package:canlifal_social/features/live/domain/pk/live_pk_event_dedup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('skips duplicate eventId', () {
    final d = LivePkEventDedup();
    final battle = {'eventId': 'e1', 'score1': 1};
    expect(d.shouldProcess(battle), isTrue);
    expect(d.shouldProcess(Map<String, dynamic>.from(battle)), isFalse);
    expect(
      d.shouldProcess({'eventId': 'e2', 'score1': 2}),
      isTrue,
    );
  });
}
