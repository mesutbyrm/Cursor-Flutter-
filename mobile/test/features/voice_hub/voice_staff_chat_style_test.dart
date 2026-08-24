import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/auth/voice_staff_rank.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_message.dart';
import 'package:canlifal_social/features/voice_hub/presentation/theme/voice_room_tokens.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_official_join.dart';
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

    test('DJ gets pink accent', () {
      const user = ChatRoomUserRef(id: '1', name: 'DJ', chatRole: 'dj');
      expect(VoiceStaffChatStyle.accentForUser(user), VoiceRoomTokens.neonPink);
      expect(VoiceStaffChatStyle.isStaffUser(user), isTrue);
    });

    test('role symbol + is staff', () {
      const voice = ChatRoomUserRef(id: '2', name: 'V', roleSymbol: '+');
      expect(VoiceStaffChatStyle.isStaffUser(voice), isTrue);
      expect(VoiceStaffChatStyle.rankOf(voice), VoiceStaffRank.voice);
    });

    test('formatStaffEntryLine for admin', () {
      const user = ChatRoomUserRef(
        id: '3',
        name: 'Mesut',
        chatRole: 'admin',
        roleSymbol: '%',
      );
      expect(
        VoiceStaffChatStyle.formatStaffEntryLine('Mesut', user: user),
        '🛡️ Admin Mesut sesli odaya giriş yaptı.',
      );
      expect(
        VoiceStaffChatStyle.formatStaffEntryLine(
          'Mesut',
          user: user,
          roomName: 'Test Oda',
        ),
        '🛡️ Admin Mesut sesli odaya giriş yaptı.',
      );
    });

    test('isStaffEntry excludes VIP banner', () {
      expect(
        VoiceStaffChatStyle.isStaffEntry(
          content: '[SYSTEM_VIP_JOIN:gold:Ali]',
        ),
        isFalse,
      );
      expect(
        VoiceStaffChatStyle.isStaffEntry(content: '% Ali odaya katıldı'),
        isTrue,
      );
    });
  });

  group('VoiceOfficialJoin home banner filter', () {
    test('staff join announcement is not a static banner', () {
      expect(
        VoiceOfficialJoin.isHomeBannerEntranceAnnouncement(
          'siteadmin GirLive sesli odasına katıldı!',
          subtitle: 'siteadmin',
        ),
        isTrue,
      );
      expect(
        VoiceOfficialJoin.isHomeBannerEntranceAnnouncement(
          'Yeni fal kampanyası',
          subtitle: 'Bu hafta %20 indirim',
        ),
        isFalse,
      );
    });
  });
}
