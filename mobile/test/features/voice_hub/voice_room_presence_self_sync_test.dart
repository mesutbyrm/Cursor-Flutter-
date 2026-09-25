import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_presence_self_sync.dart';

void main() {
  group('voice_room_presence_self_sync', () {
    test('does not inject self before backend join ack', () {
      expect(
        shouldAugmentPresenceWithSelf(
          backendJoinAcknowledged: false,
          members: const [],
          selfId: 'u1',
        ),
        isFalse,
      );
      final out = augmentPresenceWithSelf(
        backendJoinAcknowledged: false,
        members: const [],
        self: ChatRoomPresence(id: 'u1', name: 'Me'),
      );
      expect(out, isEmpty);
    });

    test('injects self only when missing after join ack', () {
      expect(
        shouldAugmentPresenceWithSelf(
          backendJoinAcknowledged: true,
          members: [ChatRoomPresence(id: 'u2', name: 'Other')],
          selfId: 'u1',
        ),
        isTrue,
      );
      final out = augmentPresenceWithSelf(
        backendJoinAcknowledged: true,
        members: [ChatRoomPresence(id: 'u2', name: 'Other')],
        self: ChatRoomPresence(id: 'u1', name: 'Me'),
      );
      expect(out, hasLength(2));
      expect(out.any((p) => p.id == 'u1'), isTrue);
    });

    test('does not duplicate self when already listed', () {
      final members = [ChatRoomPresence(id: 'u1', name: 'Me')];
      final out = augmentPresenceWithSelf(
        backendJoinAcknowledged: true,
        members: members,
        self: ChatRoomPresence(id: 'u1', name: 'Me'),
      );
      expect(out, hasLength(1));
    });
  });
}
