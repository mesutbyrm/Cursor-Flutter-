import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_permissions.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_user_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const target = ChatRoomPresence(id: 'u2', name: 'Ali');
  const selfPerms = VoiceRoomPermissions(
    isSiteAdmin: false,
    isRoomOwner: false,
    canModerate: false,
    canManageDj: false,
    canChangeBackground: false,
    canMuteUsers: true,
  );

  test('canOpenModerationSheet when only canMuteUsers', () {
    expect(VoiceRoomUserActions.canOpenModerationSheet(selfPerms), isTrue);
  });

  test('shouldOpenSelfProfile for mute-only mod tapping self', () {
    expect(
      VoiceRoomUserActions.shouldOpenSelfProfile(
        perms: selfPerms,
        selfId: 'u1',
        target: const ChatRoomPresence(id: 'u1', name: 'Me'),
      ),
      isTrue,
    );
  });

  test('should not open self profile when tapping other user', () {
    expect(
      VoiceRoomUserActions.shouldOpenSelfProfile(
        perms: selfPerms,
        selfId: 'u1',
        target: target,
      ),
      isFalse,
    );
  });

  test('full moderator opens mod sheet for self', () {
    const modPerms = VoiceRoomPermissions(
      isSiteAdmin: false,
      isRoomOwner: false,
      canModerate: true,
      canManageDj: false,
      canChangeBackground: false,
    );
    expect(
      VoiceRoomUserActions.shouldOpenSelfProfile(
        perms: modPerms,
        selfId: 'u1',
        target: const ChatRoomPresence(id: 'u1', name: 'Me'),
      ),
      isFalse,
    );
  });
}
