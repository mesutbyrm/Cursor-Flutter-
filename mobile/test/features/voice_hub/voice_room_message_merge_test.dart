import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_message.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_message_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trim keeps newest messages', () {
    final list = List.generate(
      200,
      (i) => ChatRoomMessage(
        id: '$i',
        content: 'm$i',
        createdAt: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
      ),
    );
    final trimmed = VoiceRoomMessageMerge.trim(list);
    expect(trimmed.length, VoiceRoomMessageMerge.maxRetainedMessages);
    expect(trimmed.first.id, '20');
    expect(trimmed.last.id, '199');
  });
}
