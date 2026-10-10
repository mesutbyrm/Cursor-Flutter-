import 'package:canlifal_social/features/voice_hub/girlive/girlive_publisher_advice.dart';
import 'package:canlifal_social/features/voice_hub/girlive/girlive_publisher_session_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('peak hour tip requires minimum bucket count', () {
    final m = GirLivePublisherSessionMetrics(
      roomKey: 'r1',
      startedAt: DateTime.now().subtract(const Duration(hours: 1)),
      totalVisitEvents: 10,
      hourlyJoinBuckets: {21: 1},
    );
    expect(GirLivePublisherAdvice.build(
      metrics: m,
      grossGiftJeton: 0,
      giftCount: 0,
      pkGiftsDominant: false,
    ), isEmpty);
  });

  test('PK tip only when enough completed battles and win rate', () {
    final m = GirLivePublisherSessionMetrics(
      roomKey: 'r1',
      startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      pkCompleted: 4,
      pkWon: 3,
      pkLost: 1,
    );
    final tips = GirLivePublisherAdvice.build(
      metrics: m,
      grossGiftJeton: 100,
      giftCount: 2,
      pkGiftsDominant: false,
    );
    expect(tips.any((t) => t.contains('PK')), isTrue);
  });
}
