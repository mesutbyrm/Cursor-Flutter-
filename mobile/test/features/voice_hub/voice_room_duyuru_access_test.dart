import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_duyuru_access.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_permissions.dart';

void main() {
  group('VoiceRoomDuyuruAccess', () {
    test('parseCommand extracts message', () {
      expect(
        VoiceRoomDuyuruAccess.parseCommand('!duyuru Merhaba oda'),
        'Merhaba oda',
      );
    });

    test('validateMessage enforces max length', () {
      expect(
        VoiceRoomDuyuruAccess.validateMessage('a' * 101),
        isNotNull,
      );
      expect(VoiceRoomDuyuruAccess.validateMessage('kısa'), isNull);
    });

    test('admin free, member pays jeton', () {
      const adminPerms = VoiceRoomPermissions(
        isSiteAdmin: true,
        isRoomOwner: false,
        canModerate: true,
        canManageDj: true,
        canChangeBackground: true,
      );
      const memberPerms = VoiceRoomPermissions(
        isSiteAdmin: false,
        isRoomOwner: false,
        canModerate: false,
        canManageDj: false,
        canChangeBackground: false,
      );
      expect(VoiceRoomDuyuruAccess.isAdminFree(adminPerms), isTrue);
      expect(
        VoiceRoomDuyuruAccess.canAfford(perms: memberPerms, jetonBalance: 4),
        isFalse,
      );
      expect(
        VoiceRoomDuyuruAccess.canAfford(perms: memberPerms, jetonBalance: 5),
        isTrue,
      );
    });
  });
}
