import 'package:flutter_riverpod/flutter_riverpod.dart';

/// PK / ortak yayın davetleri — global + oda içi çift dialog önleme.
class LiveInviteDedupNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  /// İlk kez görülen anahtar için `true`, tekrar için `false`.
  bool tryMark(String key) {
    final id = key.trim();
    if (id.isEmpty || state.contains(id)) return false;
    state = {...state, id};
    return true;
  }
}

final liveInviteDedupProvider =
    NotifierProvider<LiveInviteDedupNotifier, Set<String>>(
  LiveInviteDedupNotifier.new,
);

String livePkInviteDedupKey(String inviteId) => 'pk:$inviteId';

String liveCoBroadcastInviteDedupKey(String inviteId) =>
    'co:$inviteId';
