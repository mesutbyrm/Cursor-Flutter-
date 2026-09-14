import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PK accept/reject/create/end — aynı `battleId` için eşzamanlı çift API çağrısını engeller.
class LivePkActionLockNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  bool tryAcquire(String battleId, String action) {
    final id = battleId.trim();
    final act = action.trim().toLowerCase();
    if (id.isEmpty || act.isEmpty) return false;
    final key = '$id:$act';
    if (state.contains(key)) return false;
    state = {...state, key};
    return true;
  }

  void release(String battleId, String action) {
    final id = battleId.trim();
    final act = action.trim().toLowerCase();
    if (id.isEmpty || act.isEmpty) return;
    final key = '$id:$act';
    if (!state.contains(key)) return;
    state = state.where((k) => k != key).toSet();
  }
}

final livePkActionLockProvider =
    NotifierProvider<LivePkActionLockNotifier, Set<String>>(
  LivePkActionLockNotifier.new,
);
