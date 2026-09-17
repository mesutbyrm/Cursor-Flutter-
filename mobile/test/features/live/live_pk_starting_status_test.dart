import 'package:canlifal_social/features/live/domain/pk/live_pk_broadcast_stage.dart';
import 'package:canlifal_social/features/live/domain/pk/pk_status_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starting status keeps broadcast split stage', () {
    final battle = {
      'liveStreamId': 'a',
      'opponentLiveStreamId': 'b',
    };
    expect(isLivePkStartingStatus('starting'), isTrue);
    expect(
      isLivePkBroadcastStage(battle, 'starting'),
      isTrue,
    );
    expect(
      isLivePkBroadcastStage(battle, 'pending'),
      isFalse,
    );
  });
}
