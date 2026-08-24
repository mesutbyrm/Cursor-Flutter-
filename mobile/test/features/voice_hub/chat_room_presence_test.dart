import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_presence.dart';

void main() {
  test('ChatRoomPresence parses seatIndex from string or num', () {
    final fromString = ChatRoomPresence.fromJson({
      'id': 'u1',
      'name': 'Admin',
      'seatIndex': '1',
    });
    expect(fromString.seatIndex, 1);

    final fromNum = ChatRoomPresence.fromJson({
      'id': 'u2',
      'name': 'User',
      'seatIndex': 3,
    });
    expect(fromNum.seatIndex, 3);
  });
}
