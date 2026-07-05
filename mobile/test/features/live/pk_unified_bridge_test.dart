import 'package:canlifal_social/features/live/domain/pk/pk_room_models.dart';
import 'package:canlifal_social/features/live/domain/pk/pk_unified_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pk_unified_bridge', () {
    test('pkRoomMatchToBattleMap maps 1v1 scores and timer', () {
      const match = PkRoomMatch(
        id: 'pk-1',
        mode: PkRoomMode.oneVsOne,
        status: 'live',
        durationSec: 180,
        remainingSec: 45,
        leftScore: 125000,
        rightScore: 98500,
        leftName: 'Sol',
        rightName: 'Sağ',
        hostStreamId: 'stream-a',
      );
      final map = pkRoomMatchToBattleMap(match, myStreamId: 'stream-a');
      expect(map['id'], 'pk-1');
      expect(map['score1'], 125000);
      expect(map['score2'], 98500);
      expect(map['secondsLeft'], 45);
      expect(map['unifiedPk'], isTrue);
      expect(map['isOpponent'], isFalse);
    });

    test('findStreamPkMatch locates host stream', () {
      const matches = [
        PkRoomMatch(
          id: 'a',
          mode: PkRoomMode.oneVsOne,
          status: 'live',
          hostStreamId: 's1',
        ),
        PkRoomMatch(
          id: 'b',
          mode: PkRoomMode.guest,
          status: 'live',
          hostStreamId: 's2',
        ),
      ];
      expect(findStreamPkMatch(matches, 's1')?.id, 'a');
      expect(
        findStreamPkMatch(matches, 's1', mode: PkRoomMode.oneVsOne)?.id,
        'a',
      );
      expect(findStreamPkMatch(matches, 's3'), isNull);
    });

    test('pkRoomMatchToBattleRemote maps participants', () {
      const match = PkRoomMatch(
        id: 'pk-2',
        mode: PkRoomMode.oneVsOne,
        status: 'pending',
        leftScore: 10,
        rightScore: 5,
        remainingSec: 60,
        durationSec: 60,
        hostStreamId: 'host-stream',
        seats: [
          PkSeat(seatIndex: 0, userId: 'u1', team: 'left', streamId: 'host-stream'),
          PkSeat(seatIndex: 1, userId: 'u2', team: 'right', streamId: 'opp-stream'),
        ],
      );
      final remote = pkRoomMatchToBattleRemote(match, myStreamId: 'host-stream');
      expect(remote.id, 'pk-2');
      expect(remote.challengerScore, 10);
      expect(remote.opponentScore, 5);
      expect(remote.liveStreamId, 'host-stream');
      expect(remote.opponentLiveStreamId, 'opp-stream');
    });
  });
}
