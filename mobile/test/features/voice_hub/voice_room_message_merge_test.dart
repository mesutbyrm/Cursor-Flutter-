import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_message.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_message_merge.dart';

void main() {
  const user = ChatRoomUserRef(id: 'u1', name: 'Admin');

  test('replaces optimistic local message without concurrent map error', () {
    final current = List.generate(
      12,
      (i) => ChatRoomMessage(
        id: i == 11 ? 'local-99' : 'msg-$i',
        content: i == 11 ? '!istek Tarkan' : 'mesaj $i',
        createdAt: DateTime(2026, 1, 1, 0, 0, i),
        user: user,
      ),
    );
    final fetched = [
      ChatRoomMessage(
        id: 'server-99',
        content: '!istek Tarkan',
        createdAt: DateTime(2026, 1, 1, 0, 0, 11),
        user: user,
      ),
    ];

    expect(
      () => VoiceRoomMessageMerge.merge(current, fetched),
      returnsNormally,
    );

    final merged = VoiceRoomMessageMerge.merge(current, fetched);
    expect(merged, hasLength(12));
    expect(merged.any((m) => m.id == 'local-99'), isFalse);
    expect(merged.any((m) => m.id == 'server-99'), isTrue);
  });
}
