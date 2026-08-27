import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/voice_hub/domain/voice_room_join_sequence.dart';

void main() {
  test('join sequence is state before presence before SSE before seats before TRTC', () {
    expect(VoiceRoomJoinSequence.steps, [
      'auth',
      'state',
      'presence',
      'sse',
      'messages',
      'seats',
      'trtc',
    ]);
    expect(VoiceRoomJoinSequence.isBefore('state', 'sse'), isTrue);
    expect(VoiceRoomJoinSequence.isBefore('presence', 'sse'), isTrue);
    expect(VoiceRoomJoinSequence.isBefore('sse', 'seats'), isTrue);
    expect(VoiceRoomJoinSequence.isBefore('seats', 'trtc'), isTrue);
  });
}
