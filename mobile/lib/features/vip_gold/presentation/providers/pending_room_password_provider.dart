import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Odaya girmeden önce girilen şifre — `joinPresence` ile sunucuya gönderilir.
class PendingRoomPasswordNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};

  void setPassword(String roomKey, String password) {
    final key = roomKey.trim();
    final pass = password.trim();
    if (key.isEmpty || pass.isEmpty) return;
    state = {...state, key: pass};
  }

  String? take(String roomKey) {
    final key = roomKey.trim();
    if (key.isEmpty) return null;
    final pass = state[key];
    if (pass == null) return null;
    final next = Map<String, String>.from(state)..remove(key);
    state = next;
    return pass;
  }

  String? peek(String roomKey) {
    final key = roomKey.trim();
    if (key.isEmpty) return null;
    return state[key];
  }

  void clear(String roomKey) {
    final key = roomKey.trim();
    if (key.isEmpty || !state.containsKey(key)) return;
    final next = Map<String, String>.from(state)..remove(key);
    state = next;
  }
}

final pendingRoomPasswordProvider =
    NotifierProvider<PendingRoomPasswordNotifier, Map<String, String>>(
  PendingRoomPasswordNotifier.new,
);
