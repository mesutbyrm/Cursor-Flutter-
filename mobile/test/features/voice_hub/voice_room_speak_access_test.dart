import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_permissions.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_speak_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomSpeakAccess', () {
    const room = VoiceRoomEntity(
      id: 'room1',
      slug: 'sohbet',
      nameTr: 'Sohbet',
    );

    test('admin can speak without being on stage', () {
      const user = UserEntity(
        id: 'u1',
        username: 'yonetici',
        role: 'yonetici',
      );
      const perms = VoiceRoomPermissions(
        isSiteAdmin: true,
        isRoomOwner: true,
        canModerate: true,
        canManageDj: true,
        canChangeBackground: true,
        canGiveVoice: true,
        canManageRoom: true,
      );

      expect(
        VoiceRoomSpeakAccess.canSpeak(
          user: user,
          perms: perms,
          room: room,
          presence: const [],
        ),
        isTrue,
      );
    });

    test('regular user needs stage seat', () {
      const user = UserEntity(id: 'u2', username: 'guest');
      const perms = VoiceRoomPermissions(
        isSiteAdmin: false,
        isRoomOwner: false,
        canModerate: false,
        canManageDj: false,
        canChangeBackground: false,
      );

      expect(
        VoiceRoomSpeakAccess.canSpeak(
          user: user,
          perms: perms,
          room: room,
          presence: const [],
        ),
        isFalse,
      );
    });
  });
}
