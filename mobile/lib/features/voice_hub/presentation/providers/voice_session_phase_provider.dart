import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/voice/voice_session_phase.dart';

class VoiceSessionPhaseNotifier extends Notifier<VoiceSessionPhase> {
  @override
  VoiceSessionPhase build() => VoiceSessionPhase.idle;

  bool transitionTo(VoiceSessionPhase to) {
    if (!VoiceSessionPhaseGuard.canTransition(state, to)) return false;
    state = to;
    return true;
  }

  void reset() => state = VoiceSessionPhase.idle;
}

final voiceSessionPhaseProvider =
    NotifierProvider<VoiceSessionPhaseNotifier, VoiceSessionPhase>(
  VoiceSessionPhaseNotifier.new,
);
