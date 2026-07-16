import 'package:canlifal_social/core/performance/live_entry_perf.dart';
import 'package:canlifal_social/features/trtc/domain/entities/trtc_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('takeTrtc returns cached credentials once', () {
    const cred = TrtcCredentials(
      sdkAppId: 1400000000,
      userId: 'u1',
      userSig: 'sig',
      roomId: 'stream-1',
    );
    LiveEntryPerf.testPutTrtc(
      userId: 'u1',
      streamId: 'stream-1',
      cred: cred,
    );
    expect(
      LiveEntryPerf.takeTrtc(userId: 'u1', streamId: 'stream-1')?.userSig,
      'sig',
    );
    expect(LiveEntryPerf.takeTrtc(userId: 'u1', streamId: 'stream-1'), isNull);
  });
}
