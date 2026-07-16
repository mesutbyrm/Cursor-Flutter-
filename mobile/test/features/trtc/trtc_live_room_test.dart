import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/trtc/data/trtc_session_store.dart';
import 'package:canlifal_social/features/trtc/domain/entities/live_join_room_result.dart';
import 'package:canlifal_social/features/trtc/domain/entities/trtc_credentials.dart';

void main() {
  tearDown(TrtcSessionStore.clear);

  test('TrtcCredentials parses token response fields', () {
    final cred = TrtcCredentials.fromJson({
      'sdkAppId': 20040423,
      'userId': 'u1',
      'userSig': 'sig',
      'roomId': 'room-1',
      'expireTime': 86400,
      'role': 'host',
    });
    expect(cred.isValid, isTrue);
    expect(cred.expireTime, 86400);
    expect(cred.role, 'host');
  });

  test('LiveJoinRoomResult parses compound join-room payload', () {
    final result = LiveJoinRoomResult.fromJson({
      'room': {
        'id': 'room-1',
        'title': 'Canlı Fal',
        'hostId': 'h1',
        'viewerCount': 12,
      },
      'trtc': {
        'sdkAppId': 1,
        'userId': 'u1',
        'userSig': 'sig',
        'roomId': 'room-1',
      },
      'giftRanking': [
        {'userId': 'g1', 'userName': 'Ayşe', 'totalAmount': 500},
      ],
      'pkStatus': {'status': 'active'},
    });

    expect(result.room.id, 'room-1');
    expect(result.trtc.userSig, 'sig');
    expect(result.giftRanking, hasLength(1));
    expect(result.pkStatus?.isActive, isTrue);
  });

  test('TrtcSessionStore stores and expires credentials', () {
    const cred = TrtcCredentials(
      sdkAppId: 1,
      userId: 'u1',
      userSig: 'sig',
      roomId: 'room-a',
    );
    TrtcSessionStore.put(cred);
    expect(TrtcSessionStore.peek(roomId: 'room-a'), cred);
    expect(TrtcSessionStore.take(roomId: 'room-a'), cred);
    expect(TrtcSessionStore.peek(), isNull);
  });

  test('LiveHeartbeatResult parses server fields', () {
    final hb = LiveHeartbeatResult.fromJson({
      'onlineCount': 42,
      'staleRemoved': 2,
      'serverTime': '2026-07-16T12:00:00Z',
    });
    expect(hb.onlineCount, 42);
    expect(hb.staleRemoved, 2);
    expect(hb.serverTime, isNotNull);
  });
}
