import 'package:canlifal_social/core/network/voice_event_log.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice/voice_session_phase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VoiceSessionPhaseGuard blocks duplicate transition', () {
    expect(
      VoiceSessionPhaseGuard.canTransition(
        VoiceSessionPhase.joining,
        VoiceSessionPhase.joining,
      ),
      isFalse,
    );
  });

  test('VoiceSessionPhaseGuard allows join to connected', () {
    expect(
      VoiceSessionPhaseGuard.canTransition(
        VoiceSessionPhase.joining,
        VoiceSessionPhase.connected,
      ),
      isTrue,
    );
  });

  test('VoiceSessionPhaseGuard allows connected to reconnecting', () {
    expect(
      VoiceSessionPhaseGuard.canTransition(
        VoiceSessionPhase.connected,
        VoiceSessionPhase.reconnecting,
      ),
      isTrue,
    );
    expect(
      VoiceSessionPhaseGuard.canTransition(
        VoiceSessionPhase.reconnecting,
        VoiceSessionPhase.connected,
      ),
      isTrue,
    );
  });

  test('VoiceEventLog sanitizes secrets', () {
    final out = VoiceEventLog.sanitize({
      'roomId': 'r1',
      'token': 'secret',
    });
    expect(out['roomId'], 'r1');
    expect(out.containsKey('token'), isFalse);
  });
}
