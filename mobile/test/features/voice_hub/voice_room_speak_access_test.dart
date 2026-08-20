import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
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

    const adminPerms = VoiceRoomPermissions(
      isSiteAdmin: true,
      isRoomOwner: true,
      canModerate: true,
      canManageDj: true,
      canChangeBackground: true,
      canGiveVoice: true,
      canManageRoom: true,
    );

    const listenerPerms = VoiceRoomPermissions(
      isSiteAdmin: false,
      isRoomOwner: false,
      canModerate: false,
      canManageDj: false,
      canChangeBackground: false,
    );

    const voiceRolePerms = VoiceRoomPermissions(
      isSiteAdmin: false,
      isRoomOwner: false,
      canModerate: false,
      canManageDj: false,
      canChangeBackground: false,
      canGiveVoice: true,
    );

    test('admin can speak without backend seat', () {
      const user = UserEntity(
        id: 'u1',
        username: 'yonetici',
        role: 'yonetici',
      );

      expect(
        VoiceRoomSpeakAccess.canSpeak(
          user: user,
          perms: adminPerms,
          room: room,
          presence: const [],
        ),
        isTrue,
      );
    });

    test('+V grant permission alone does not allow off-seat speak', () {
      const user = UserEntity(id: 'u2', username: 'voiceuser');

      expect(
        VoiceRoomSpeakAccess.canSpeak(
          user: user,
          perms: voiceRolePerms,
          room: room,
          presence: const [],
        ),
        isFalse,
      );
    });

    test('+V user with backend seat can speak', () {
      const user = UserEntity(id: 'u2', username: 'voiceuser');
      const presence = [
        ChatRoomPresence(id: 'u2', name: 'voiceuser', seatIndex: 3),
      ];

      expect(
        VoiceRoomSpeakAccess.canSpeak(
          user: user,
          perms: voiceRolePerms,
          room: room,
          presence: presence,
        ),
        isTrue,
      );
    });

    test('layout fill without backend seat does not grant speak', () {
      const user = UserEntity(id: 'u3', username: 'guest');

      expect(
        VoiceRoomSpeakAccess.hasBackendSeat(userId: 'u3', presence: const [
          ChatRoomPresence(id: 'u3', name: 'guest'),
        ]),
        isFalse,
      );

      expect(
        VoiceRoomSpeakAccess.canSpeak(
          user: user,
          perms: listenerPerms,
          room: room,
          presence: const [
            ChatRoomPresence(id: 'u3', name: 'guest'),
          ],
        ),
        isFalse,
      );
    });

    test('muted user cannot speak even on seat', () {
      const user = UserEntity(id: 'u4', username: 'muted');
      const presence = [
        ChatRoomPresence(
          id: 'u4',
          name: 'muted',
          seatIndex: 2,
          isMuted: true,
        ),
      ];

      expect(
        VoiceRoomSpeakAccess.canSpeak(
          user: user,
          perms: listenerPerms,
          room: room,
          presence: presence,
        ),
        isFalse,
      );
    });

    test('moderator can speak off-seat', () {
      const user = UserEntity(id: 'u5', username: 'mod');
      const modPerms = VoiceRoomPermissions(
        isSiteAdmin: false,
        isRoomOwner: false,
        canModerate: true,
        canManageDj: true,
        canChangeBackground: true,
      );

      expect(
        VoiceRoomSpeakAccess.canSpeak(
          user: user,
          perms: modPerms,
          room: room,
          presence: const [],
        ),
        isTrue,
      );
    });
  });
}
