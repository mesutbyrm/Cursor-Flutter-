import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('live guest paths are distinct from guest list', () {
    expect(ApiEndpoints.liveGuest, '/api/live/guest');
    expect(ApiEndpoints.liveGuestList, '/api/live/guest/list');
    expect(ApiEndpoints.liveGuest, isNot(ApiEndpoints.liveGuestList));
  });

  test('live guest POST compat body uses action streamId optional userId', () {
    const streamId = 'stream-1';
    const body = {
      'action': 'approve',
      'streamId': streamId,
      'userId': 'u1',
    };
    expect(body.keys, containsAll(['action', 'streamId', 'userId']));
    expect(body['streamId'], streamId);
  });

  test('live PK and video-stream PK paths', () {
    expect(ApiEndpoints.livePk, '/api/live/pk');
    expect(ApiEndpoints.videoStreamPk, '/api/video-streams/pk');
    expect(
      ApiEndpoints.videoStreamPkBattle('s1'),
      '/api/video-streams/s1/pk-battle',
    );
  });
}
