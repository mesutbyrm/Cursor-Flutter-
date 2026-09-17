import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PK `ended` geçişinde kısa süreli görsel efekt (konfeti/karartma) — battle id
/// için yalnızca bir kez (`livePkActionLockProvider` deseni).
class LivePkEndedLockNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  bool tryAcquireEndedCelebration(String battleId) {
    final id = battleId.trim();
    if (id.isEmpty || state.contains(id)) return false;
    state = {...state, id};
    return true;
  }

  void release(String battleId) {
    final id = battleId.trim();
    if (id.isEmpty || !state.contains(id)) return;
    state = state.where((k) => k != id).toSet();
  }
}

final livePkEndedLockProvider =
    NotifierProvider<LivePkEndedLockNotifier, Set<String>>(
  LivePkEndedLockNotifier.new,
);
