import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presence heartbeat interval is 25 seconds', () {
    expect(
      ChatRoomRemoteDataSource.presenceHeartbeatInterval.inSeconds,
      25,
    );
  });
}
