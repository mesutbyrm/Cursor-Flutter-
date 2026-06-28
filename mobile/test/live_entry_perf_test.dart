import 'package:canlifal_social/core/performance/live_entry_perf.dart';
import 'package:canlifal_social/features/agora/domain/entities/agora_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('takeAgora returns cached credentials once', () {
    const cred = AgoraCredentials(
      token: 'tok',
      channelName: 'stream-1',
      appId: AgoraCredentials.defaultAppId,
    );
    LiveEntryPerf.testPutAgora(
      userId: 'u1',
      streamId: 'stream-1',
      cred: cred,
    );
    expect(
      LiveEntryPerf.takeAgora(userId: 'u1', streamId: 'stream-1')?.token,
      'tok',
    );
    expect(LiveEntryPerf.takeAgora(userId: 'u1', streamId: 'stream-1'), isNull);
  });
}
