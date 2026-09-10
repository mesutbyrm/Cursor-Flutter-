import 'package:canlifal_social/features/live/domain/pk/pk_status_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isPkInvitePendingStatus accepts pending variants', () {
    expect(isPkInvitePendingStatus('pending'), isTrue);
    expect(isPkInvitePendingStatus('invited'), isTrue);
    expect(isPkInvitePendingStatus('created'), isTrue);
    expect(isPkInvitePendingStatus('active'), isFalse);
  });

  test('isLivePkSplitReady requires active status and both stream ids', () {
    expect(
      isLivePkSplitReady(
        {
          'liveStreamId': 'a',
          'opponentLiveStreamId': 'b',
        },
        'active',
      ),
      isTrue,
    );
    expect(
      isLivePkSplitReady(
        {'liveStreamId': 'a'},
        'active',
      ),
      isFalse,
    );
    expect(
      isLivePkSplitReady(
        {
          'liveStreamId': 'a',
          'opponentLiveStreamId': 'b',
        },
        'pending',
      ),
      isFalse,
    );
  });
}
