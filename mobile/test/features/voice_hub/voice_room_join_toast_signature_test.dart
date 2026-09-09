import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_message.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/voice_room_realtime_event.dart';
import 'package:canlifal_social/features/voice_hub/presentation/widgets/voice_room/voice_room_join_toast_stack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('voiceRoomJoinToastSignature', () {
    test('unchanged when only text messages change', () {
      final join = ChatRoomMessage(
        id: 'j1',
        kind: ChatMessageKind.systemJoin,
        content: 'Ali odaya katıldı',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final textA = ChatRoomMessage(
        id: 't1',
        kind: ChatMessageKind.text,
        content: 'merhaba',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final textB = ChatRoomMessage(
        id: 't2',
        kind: ChatMessageKind.text,
        content: 'nasılsın',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final sigA = voiceRoomJoinToastSignature(
        messages: [join, textA],
        events: const [],
      );
      final sigB = voiceRoomJoinToastSignature(
        messages: [join, textA, textB],
        events: const [],
      );

      expect(sigA, sigB);
    });

    test('changes when join/leave message added', () {
      final join = ChatRoomMessage(
        id: 'j1',
        kind: ChatMessageKind.systemJoin,
        content: 'Ali odaya katıldı',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final leave = ChatRoomMessage(
        id: 'l1',
        kind: ChatMessageKind.systemLeave,
        content: 'Ali çıktı',
        createdAt: DateTime.utc(2026, 1, 1),
      );

      final before = voiceRoomJoinToastSignature(messages: [join], events: const []);
      final after = voiceRoomJoinToastSignature(
        messages: [join, leave],
        events: const [],
      );

      expect(before, isNot(equals(after)));
    });

    test('changes when realtime join event added', () {
      final event = VoiceRoomRealtimeEvent(
        kind: VoiceRoomRealtimeKind.join,
        message: 'Veli giriş yaptı',
        at: DateTime.utc(2026, 1, 1),
      );

      final before = voiceRoomJoinToastSignature(messages: const [], events: const []);
      final after = voiceRoomJoinToastSignature(messages: const [], events: [event]);

      expect(before, isNot(equals(after)));
    });
  });
}
