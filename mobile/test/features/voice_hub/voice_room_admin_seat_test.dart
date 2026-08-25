import 'package:canlifal_social/features/auth/domain/entities/user_entity.dart';
import 'package:canlifal_social/features/live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_permissions.dart';
import 'package:canlifal_social/features/voice_hub/presentation/utils/voice_room_seat_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VoiceRoomSeatPriority site admin', () {
    const room = VoiceRoomEntity(id: 'room1', slug: 'room1', nameTr: 'Test');

    test('site admin flag grants admin tier for auto seat', () {
      const user = UserEntity(
        id: 'admin1',
        username: 'admin',
        displayName: 'Admin',
      );
      final perms = VoiceRoomPermissions.forUser(
        user: user,
        room: room,
        staffSiteAdmin: true,
      );
      expect(perms.isSiteAdmin, isTrue);

      final tier = VoiceRoomSeatPriority.forUser(
        user,
        room: room,
        server: null,
      );
      expect(tier, VoiceRoomSeatPriority.tierAdmin);
      expect(VoiceRoomSeatPriority.shouldAutoSit(tier), isTrue);
    });
  });
}
