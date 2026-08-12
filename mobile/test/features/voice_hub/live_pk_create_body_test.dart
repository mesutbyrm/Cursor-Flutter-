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
  });
}
