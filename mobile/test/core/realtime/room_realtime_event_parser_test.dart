import 'package:canlifal_social/core/realtime/room_realtime_event_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isPkInviteEvent normalizes invite aliases', () {
    expect(RoomRealtimeEventParser.isPkInviteEvent('pk_invite'), isTrue);
    expect(RoomRealtimeEventParser.isPkInviteEvent('PKRequest'), isTrue);
    expect(RoomRealtimeEventParser.isPkInviteEvent('gift'), isFalse);
  });

  test('payloadLooksLikePk detects battle payload', () {
    expect(
      RoomRealtimeEventParser.payloadLooksLikePk({'inviteId': 'x', 'status': 'invited'}),
      isTrue,
    );
    expect(RoomRealtimeEventParser.payloadLooksLikePk({'text': 'hello'}), isFalse);
  });
}
