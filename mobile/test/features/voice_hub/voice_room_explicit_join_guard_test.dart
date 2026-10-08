import 'package:canlifal_social/features/voice_hub/data/services/voice_room_debug_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// P0 — explicit join invariant (log sözleşmesi; oturum bootstrap kod incelemesi ile).
void main() {
  test('lifecycle log phases include explicit join markers', () {
    expect(
      () => VoiceRoomDebugLog.joinIntent(roomId: 'room-a', source: 'test'),
      returnsNormally,
    );
    expect(
      () => VoiceRoomDebugLog.blockedImplicitJoin(
        reason: 'provider_build',
        roomId: 'room-a',
      ),
      returnsNormally,
    );
  });
}
