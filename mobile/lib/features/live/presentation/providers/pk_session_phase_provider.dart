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

  /// SSE/REST canonical durum — guard atlanır (faz uyumsuzluğu donmasını önler).
  void syncFromServer({
    required bool isEnded,
    required bool isActive,
    required bool isPending,
    String? status,
  }) {
    if (isEnded) {
      state = status == 'rejected'
          ? PkSessionPhase.rejected
          : PkSessionPhase.ended;
      return;
    }
    if (isActive) {
      state = PkSessionPhase.active;
      return;
    }
    if (isPending) {
      if (state == PkSessionPhase.requesting ||
          state == PkSessionPhase.accepting) {
        return;
      }
      state = PkSessionPhase.incoming;
    }
  }

  void reset() => state = PkSessionPhase.idle;
}

final pkSessionPhaseProvider =
    NotifierProvider<PkSessionPhaseNotifier, PkSessionPhase>(
  PkSessionPhaseNotifier.new,
);
