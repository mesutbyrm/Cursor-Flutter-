import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_my_permissions.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatRoomMyPermissions', () {
    test('parses snake_case and truthy values', () {
      final p = ChatRoomMyPermissions.fromJson({
        'can_give_voice': 'true',
        'canMuteUsers': 1,
        'is_room_owner': false,
      });
      expect(p.canGiveVoice, isTrue);
      expect(p.canMuteUsers, isTrue);
      expect(p.hasAnyServerFlag, isTrue);
      expect(p.canModerate, isTrue);
    });
  });

  group('VoiceRoomPermissions server canGiveVoice', () {
    const room = VoiceRoomEntity(
      id: 'r1',
      slug: 'sohbet',
      nameTr: 'Sohbet',
    );
    const user = UserEntity(id: 'u1', username: 'ali', displayName: 'Ali');

    test('honors canGiveVoice when canModerate would be false without it', () {
      const server = ChatRoomMyPermissions(canGiveVoice: true);
      final perms = VoiceRoomPermissions.forUser(
        user: user,
        room: room,
        server: server,
      );
      expect(perms.canGiveVoice, isTrue);
      expect(perms.canTakeSeat, isTrue);
    });
  });
}
