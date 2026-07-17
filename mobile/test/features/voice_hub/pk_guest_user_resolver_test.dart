import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_guest_user_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolvePkGuestUserId prefers ownerId metadata', () {
    expect(
      resolvePkGuestUserId(ownerId: 'owner-1'),
      'owner-1',
    );
  });

  test('resolvePkGuestUserId falls back to host seat', () {
    const presence = [
      ChatRoomPresence(id: 'u1', name: 'A', seatIndex: 2),
      ChatRoomPresence(id: 'host', name: 'Host', seatIndex: 1),
    ];
    expect(
      resolvePkGuestUserId(presence: presence),
      'host',
    );
  });

  test('resolvePkGuestUserId uses owner chatRole', () {
    const presence = [
      ChatRoomPresence(id: 'owner', name: 'Owner', chatRole: 'owner'),
      ChatRoomPresence(id: 'u2', name: 'B', seatIndex: 1),
    ];
    expect(
      resolvePkGuestUserId(presence: presence),
      'owner',
    );
  });
}
