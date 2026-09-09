import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Yayıncının «bu kişiye kapat» dediği misafir istekleri (oturum içi).
class LiveGuestRequestBlocklistNotifier
    extends AutoDisposeFamilyNotifier<Set<String>, String> {
  @override
  Set<String> build(String streamId) => {};

  bool isBlocked(String userId) => state.contains(userId.trim());

  void block(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return;
    state = {...state, id};
  }

  void unblock(String userId) {
    final id = userId.trim();
    if (id.isEmpty || !state.contains(id)) return;
    state = Set<String>.from(state)..remove(id);
  }
}

final liveGuestRequestBlocklistProvider = NotifierProvider.autoDispose
    .family<LiveGuestRequestBlocklistNotifier, Set<String>, String>(
  LiveGuestRequestBlocklistNotifier.new,
);
