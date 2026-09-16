import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Seat take/leave — aynı kullanıcı+koltuk için eşzamanlı çift API çağrısını engeller
/// (`livePkActionLockProvider` deseni).
class VoiceSeatActionLockNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  bool tryAcquire(String userId, String action, {int? seatIndex}) {
    final uid = userId.trim();
    final act = action.trim().toLowerCase();
    if (uid.isEmpty || act.isEmpty) return false;
    final seat = seatIndex == null ? '' : ':$seatIndex';
    final key = '$uid:$act$seat';
    if (state.contains(key)) return false;
    state = {...state, key};
    return true;
  }

  void release(String userId, String action, {int? seatIndex}) {
    final uid = userId.trim();
    final act = action.trim().toLowerCase();
    if (uid.isEmpty || act.isEmpty) return;
    final seat = seatIndex == null ? '' : ':$seatIndex';
    final key = '$uid:$act$seat';
    if (!state.contains(key)) return;
    state = state.where((k) => k != key).toSet();
  }
}

final voiceSeatActionLockProvider =
    NotifierProvider<VoiceSeatActionLockNotifier, Set<String>>(
  VoiceSeatActionLockNotifier.new,
);
