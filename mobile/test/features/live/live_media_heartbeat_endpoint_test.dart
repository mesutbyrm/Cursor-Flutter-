import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/core/network/api_endpoints.dart';

void main() {
  test('videoStreamMediaHeartbeat uses canonical backend path', () {
    expect(
      ApiEndpoints.videoStreamMediaHeartbeat('stream-abc'),
      '/api/video-streams/stream-abc/media-heartbeat',
    );
  });
}
