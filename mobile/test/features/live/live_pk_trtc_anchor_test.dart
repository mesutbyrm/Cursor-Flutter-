import 'package:canlifal_social/features/live/domain/pk/live_pk_trtc_anchor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveLivePkTrtcAnchor', () {
    test('opponent stream joins host TRTC room (shared pk room)', () {
      const battle = {
        'id': 'pk-session-99',
        'liveStreamId': 'stream-host',
        'opponentLiveStreamId': 'stream-guest',
        'challengerId': 'user-host',
        'opponentId': 'user-guest',
      };

      final host = resolveLivePkTrtcAnchor(
        battle: battle,
        myStreamId: 'stream-host',
        myUserId: 'user-host',
      );
      final guest = resolveLivePkTrtcAnchor(
        battle: battle,
        myStreamId: 'stream-guest',
        myUserId: 'user-guest',
      );

      expect(host.trtcRoomId, 'stream-host');
      expect(guest.trtcRoomId, 'stream-host');
      expect(host.expectedRemoteUserId, 'user-guest');
      expect(guest.expectedRemoteUserId, 'user-host');
      expect(host.pkSessionId, 'pk-session-99');
    });

    test('uses explicit pkRoomId / trtcRoomId when provided', () {
      const battle = {
        'pkRoomId': 'pk-room-abc',
        'liveStreamId': 'stream-a',
        'opponentLiveStreamId': 'stream-b',
        'challengerId': 'u1',
        'opponentId': 'u2',
      };

      final a = resolveLivePkTrtcAnchor(
        battle: battle,
        myStreamId: 'stream-a',
        myUserId: 'u1',
      );
      final b = resolveLivePkTrtcAnchor(
        battle: battle,
        myStreamId: 'stream-b',
        myUserId: 'u2',
      );

      expect(a.trtcRoomId, 'pk-room-abc');
      expect(b.trtcRoomId, 'pk-room-abc');
    });

    test('pkSessionId (battle id) does not override host stream TRTC room', () {
      const battle = {
        'id': 'uuid-battle-only',
        'pkSessionId': 'uuid-battle-only',
        'liveStreamId': 'stream-host',
        'opponentLiveStreamId': 'stream-guest',
        'challengerId': 'u1',
        'opponentId': 'u2',
      };

      final guest = resolveLivePkTrtcAnchor(
        battle: battle,
        myStreamId: 'stream-guest',
        myUserId: 'u2',
      );
      expect(guest.trtcRoomId, 'stream-host');
    });
  });
}
