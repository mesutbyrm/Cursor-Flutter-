import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_mention.dart';

void main() {
  group('VoiceRoomMention', () {
    const mesut = ChatRoomPresence(
      id: 'u1',
      name: 'Mesut',
      nickname: 'Mesut',
    );
    const ali = ChatRoomPresence(
      id: 'u2',
      name: 'Ali',
      nickname: 'Ali',
    );

    test('detectQuery finds active @ mention', () {
      const text = 'Selam @Me';
      final query = VoiceRoomMention.detectQuery(
        text,
        const TextSelection.collapsed(offset: text.length),
      );
      expect(query?.query, 'Me');
    });

    test('insertMention adds @Mesut', () {
      final controller = TextEditingController(text: 'Selam @');
      const trigger = VoiceRoomMentionQuery(atIndex: 6, query: '');
      VoiceRoomMention.insertMention(
        controller: controller,
        handle: 'Mesut',
        trigger: trigger,
      );
      expect(controller.text, 'Selam @Mesut ');
    });

    test('resolveMentionedUserIds matches presence', () {
      final ids = VoiceRoomMention.resolveMentionedUserIds(
        'Selam @Mesut nasılsın?',
        const [mesut, ali],
      );
      expect(ids, ['u1']);
    });
  });
}
