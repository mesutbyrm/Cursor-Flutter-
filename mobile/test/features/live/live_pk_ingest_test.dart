import 'package:canlifal_social/features/live/domain/pk/live_pk_ingest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('livePkBattleIngestFingerprint changes on status and scores', () {
    final a = livePkBattleIngestFingerprint({
      'id': 'pk-1',
      'status': 'pending',
      'score1': 0,
      'score2': 0,
      'liveStreamId': 's1',
      'opponentLiveStreamId': 's2',
    });
    final b = livePkBattleIngestFingerprint({
      'id': 'pk-1',
      'status': 'active',
      'score1': 0,
      'score2': 0,
      'liveStreamId': 's1',
      'opponentLiveStreamId': 's2',
    });
    expect(a, isNot(equals(b)));
  });

  test('livePkBattleIngestFingerprint stable for duplicate SSE', () {
    final map = {
      'eventId': 'evt-9',
      'id': 'pk-1',
      'status': 'pending',
      'score1': 10,
      'score2': 5,
    };
    expect(
      livePkBattleIngestFingerprint(map),
      livePkBattleIngestFingerprint(Map<String, dynamic>.from(map)),
    );
  });
}
