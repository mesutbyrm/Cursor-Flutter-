import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pk/pk_session_phase.dart';

class PkSessionPhaseNotifier extends Notifier<PkSessionPhase> {
  @override
  PkSessionPhase build() => PkSessionPhase.idle;

  bool transitionTo(PkSessionPhase to) {
    if (!PkSessionPhaseGuard.canTransition(state, to)) return false;
    state = to;
    return true;
  }

  void reset() => state = PkSessionPhase.idle;
}

final pkSessionPhaseProvider =
    NotifierProvider<PkSessionPhaseNotifier, PkSessionPhase>(
  PkSessionPhaseNotifier.new,
);
