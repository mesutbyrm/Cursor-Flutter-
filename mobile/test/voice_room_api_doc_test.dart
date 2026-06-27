import 'package:canlifal_social/features/voice_hub/data/datasources/chat_room_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presence heartbeat matches sesli-sohbet API doc (25s)', () {
    expect(
      ChatRoomRemoteDataSource.presenceHeartbeatInterval.inSeconds,
      25,
    );
  });
}
