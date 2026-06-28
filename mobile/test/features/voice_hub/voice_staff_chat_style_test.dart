import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/auth/voice_staff_rank.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_message.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_staff_chat_style.dart';

void main() {
  group('VoiceStaffChatStyle', () {
    test('detects moderator as staff', () {
      const user = ChatRoomUserRef(
        id: '1',
        name: 'Mod',
        chatRole: 'moderator',
      );
      expect(VoiceStaffChatStyle.isStaffUser(user), isTrue);
    });

    test('rank colors differ by level', () {
      expect(
        VoiceStaffChatStyle.accentFor(VoiceStaffRank.admin),
        isNot(VoiceStaffChatStyle.accentFor(VoiceStaffRank.op)),
      );
    });
  });
}
