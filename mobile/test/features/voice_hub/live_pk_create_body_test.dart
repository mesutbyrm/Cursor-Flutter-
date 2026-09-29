import 'package:canlifal_social/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('livePkCreateRequestBody includes streamId and targetStreamId', () {
    final body = livePkCreateRequestBody(
      hostStreamId: 'stream-host',
      targetStreamId: 'stream-target',
      durationSeconds: 180,
    );
    expect(body['action'], 'create');
    expect(body['streamId'], 'stream-host');
    expect(body['targetStreamId'], 'stream-target');
    expect(body['opponentStreamId'], 'stream-target');
    expect(body['duration'], 180);
    expect(body['durationSec'], 180);
    expect(body['durationMinutes'], 3);
    expect(body.containsKey('hostStreamId'), isFalse);
  });

  test('livePkCreateRequestBodies canonical first then alias helper', () {
    final bodies = livePkCreateRequestBodies(
      hostStreamId: 'stream-host',
      targetStreamId: 'stream-target',
      durationSeconds: 300,
    );
    expect(bodies.length, 2);
    expect(bodies.first['action'], 'create');
    expect(bodies.first['streamId'], 'stream-host');
    expect(bodies.first['targetStreamId'], 'stream-target');
    expect(bodies.first['duration'], 300);
    expect(bodies.last['durationMinutes'], 5);
  });
}
