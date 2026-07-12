import 'package:canlifal_social/features/live/domain/entities/live_guest_layout.dart';
import 'package:canlifal_social/features/live/domain/live_guest_layout_resolver.dart';
import 'package:canlifal_social/features/live/domain/pk/live_pk_invite_helper.dart';
import 'package:canlifal_social/features/live/domain/pk/pk_room_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('live_pk_invite_helper', () {
    const pendingMatch = PkRoomMatch(
      id: 'pk-1',
      mode: PkRoomMode.oneVsOne,
      status: 'pending',
      hostStreamId: 'stream-a',
      hostUserId: 'host-user',
      seats: [
        PkSeat(seatIndex: 0, userId: 'host-user', streamId: 'stream-a'),
        PkSeat(seatIndex: 1, userId: 'opp-user', streamId: 'stream-b'),
      ],
    );

    test('recipient is opponent stream host', () {
      expect(
        isLivePkInviteRecipient(
          pendingMatch,
          myStreamId: 'stream-b',
          myUserId: 'opp-user',
        ),
        isTrue,
      );
      expect(
        isLivePkInviteRecipient(
          pendingMatch,
          myStreamId: 'stream-a',
          myUserId: 'host-user',
        ),
        isFalse,
      );
    });

    test('recipient map matches opponent stream', () {
      final map = {
        'status': 'pending',
        'hostStreamId': 'stream-a',
        'seats': [
          {'userId': 'host-user', 'streamId': 'stream-a'},
          {'userId': 'opp-user', 'streamId': 'stream-b'},
        ],
      };
      expect(
        isLivePkInviteRecipientMap(
          map,
          myStreamId: 'stream-b',
          myUserId: 'opp-user',
        ),
        isTrue,
      );
    });
  });

  group('resolveGuestLayout', () {
    test('single guest uses duo', () {
      expect(resolveGuestLayout(guestCount: 1), LiveGuestLayout.duo);
    });
    test('gridSlots from API', () {
      expect(
        resolveGuestLayout(guestCount: 0, gridSlots: 4),
        LiveGuestLayout.quad,
      );
    });
  });
}
