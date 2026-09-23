import 'package:canlifal_social/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('voicePkInviteRequestBodies prefers games action create with targetRoomId',
      () {
    final bodies = voicePkInviteRequestBodies(
      opponentRoomId: 'room-b',
      guestUserId: 'user-guest',
      durationSeconds: 180,
    );
    expect(bodies.first['action'], 'create');
    expect(bodies.first['targetRoomId'], 'room-b');
    expect(bodies.first['duration'], 180);
    expect(bodies.last['guestUserId'], 'user-guest');
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

  test('livePkCreateRequestBodies starts with guide opponentStreamId + durationMinutes',
      () {
    final bodies = livePkCreateRequestBodies(
      hostStreamId: 'host',
      targetStreamId: 'target',
      durationSeconds: 180,
    );
    expect(bodies.first['opponentStreamId'], 'target');
    expect(bodies.first['durationMinutes'], 3);
    expect(bodies.last['action'], 'create');
  });
}
