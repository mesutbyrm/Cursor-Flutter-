import 'package:canlifal_social/features/live/presentation/utils/live_pk_invite_flow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isLivePkIncomingInviteForHost detects recipient pending', () {
    final battle = {
      'status': 'invited',
      'opponentStreamId': 'stream-b',
      'hostStreamId': 'stream-a',
      'challengerId': 'user-a',
      'opponentId': 'user-b',
    };
    expect(
      isLivePkIncomingInviteForHost(battle, 'stream-b', 'user-b'),
      isTrue,
    );
    expect(
      isLivePkIncomingInviteForHost(battle, 'stream-a', 'user-a'),
      isFalse,
    );
  });

  test('isLivePkOutgoingInvite detects challenger pending', () {
    final battle = {
      'status': 'pending',
      'challengerId': 'user-a',
    };
    expect(isLivePkOutgoingInvite(battle, 'user-a'), isTrue);
    expect(isLivePkOutgoingInvite(battle, 'user-b'), isFalse);
  });
}
