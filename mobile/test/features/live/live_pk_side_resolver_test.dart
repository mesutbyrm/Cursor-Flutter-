import 'package:canlifal_social/features/live/domain/pk/live_pk_side_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('broadcaster challenger sees self on left', () {
    final layout = resolveLivePkSplitLayout(
      battle: {
        'liveStreamId': 'stream-a',
        'opponentLiveStreamId': 'stream-b',
        'leftName': 'Admin',
        'rightName': 'Rival',
        'challengerId': 'user-a',
        'opponentId': 'user-b',
      },
      myStreamId: 'stream-a',
      myUserId: 'user-a',
      amBroadcaster: true,
    );
    expect(layout.left.isLocalPane, isTrue);
    expect(layout.left.label, 'Admin');
    expect(layout.right.label, 'Rival');
    expect(layout.right.streamId, 'stream-b');
  });

  test('broadcaster opponent sees self on left', () {
    final layout = resolveLivePkSplitLayout(
      battle: {
        'liveStreamId': 'stream-a',
        'opponentLiveStreamId': 'stream-b',
        'leftName': 'Admin',
        'rightName': 'Rival',
        'challengerId': 'user-a',
        'opponentId': 'user-b',
      },
      myStreamId: 'stream-b',
      myUserId: 'user-b',
      amBroadcaster: true,
    );
    expect(layout.left.isLocalPane, isTrue);
    expect(layout.left.label, 'Rival');
    expect(layout.right.label, 'Admin');
  });

  test('viewer sees host stream on left', () {
    final layout = resolveLivePkSplitLayout(
      battle: {
        'liveStreamId': 'stream-a',
        'opponentLiveStreamId': 'stream-b',
        'leftName': 'Admin',
        'rightName': 'Rival',
      },
      myStreamId: 'stream-a',
      amBroadcaster: false,
    );
    expect(layout.left.isLocalPane, isFalse);
    expect(layout.left.streamId, 'stream-a');
    expect(layout.right.streamId, 'stream-b');
  });
}
