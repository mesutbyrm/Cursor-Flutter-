import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_server_leave_dedupe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VoiceRoomServerLeaveDedupe coalesces concurrent calls', () async {
    var runs = 0;
    final first = VoiceRoomServerLeaveDedupe.run(
      roomKey: 'room-a',
      userId: 'u1',
      operation: () async {
        runs++;
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return true;
      },
    );
    final second = VoiceRoomServerLeaveDedupe.run(
      roomKey: 'room-a',
      userId: 'u1',
      operation: () async {
        runs++;
        return false;
      },
    );
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(runs, 1);
  });
}
