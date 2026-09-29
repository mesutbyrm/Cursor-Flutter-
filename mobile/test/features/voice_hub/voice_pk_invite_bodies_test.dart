import 'package:canlifal_social/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voicePkInviteRequestBodies prefers action create with targetRoomId',
      () {
    final bodies = voicePkInviteRequestBodies(
      opponentRoomId: 'room-b',
      guestUserId: 'user-guest',
      durationSeconds: 180,
    );
    expect(bodies.first['action'], 'create');
    expect(bodies.first['targetRoomId'], 'room-b');
    expect(bodies.first['duration'], 180);
    expect(bodies[1]['targetRoomId'], 'room-b');
  });

  test('first body carries both targetRoomId and guestUserId for main backend',
      () {
    final bodies = voicePkInviteRequestBodies(
      opponentRoomId: 'room-b',
      guestUserId: 'user-guest',
      durationSeconds: 180,
    );
    expect(bodies.first['targetRoomId'], 'room-b');
    expect(bodies.first['guestUserId'], 'user-guest');
    expect(bodies.first['durationSec'], 180);
    expect(bodies.length, 2);
    expect(bodies[1].containsKey('guestUserId'), isFalse);
  });

  test('voicePkInviteRequestBodies works without guestUserId', () {
    final bodies = voicePkInviteRequestBodies(
      opponentRoomId: 'room-b',
      durationSeconds: 120,
    );
    expect(bodies.first['targetRoomId'], 'room-b');
    expect(bodies.first.containsKey('guestUserId'), isFalse);
    expect(bodies.any((b) => b.containsKey('guestUserId')), isFalse);
  });

  test('livePkCreateRequestBodies uses canonical video-streams pk create',
      () {
    final bodies = livePkCreateRequestBodies(
      hostStreamId: 'host',
      targetStreamId: 'target',
      durationSeconds: 180,
    );
    expect(bodies.first['action'], 'create');
    expect(bodies.first['streamId'], 'host');
    expect(bodies.first['targetStreamId'], 'target');
    expect(bodies.first['duration'], 180);
    expect(bodies.length, 2);
    expect(bodies.last['durationMinutes'], 3);
  });
}
