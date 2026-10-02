import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/room_access_remote_datasource.dart';

final roomAccessRemoteProvider = Provider<RoomAccessRemoteDataSource>(
  (ref) => RoomAccessRemoteDataSource(ref.watch(dioProvider)),
);

/// Sunucunun `verify-password` sonrası verdiği kısa ömürlü, imzalı erişim
/// jetonu (oda anahtarı → jeton). Şifrenin kendisi ASLA saklanmaz.
///
/// `joinPresence` / `join-room` isteğine `roomAccessToken` olarak eklenir;
/// yetkilendirme kararı yine sunucudadır (istemci "onaylandı" bayrağına
/// güvenmez). Jeton süresi dolmuşsa [peek] `null` döner.
class RoomAccessTokenNotifier extends Notifier<Map<String, _Token>> {
  @override
  Map<String, _Token> build() => {};

  void set(String roomKey, String token, DateTime expiresAt) {
    final key = roomKey.trim();
    if (key.isEmpty || token.isEmpty) return;
    state = {...state, key: _Token(token, expiresAt)};
  }

  String? peek(String roomKey) {
    final t = state[roomKey.trim()];
    if (t == null) return null;
    if (t.expiresAt.isBefore(DateTime.now())) return null;
    return t.value;
  }

  void clear(String roomKey) {
    final key = roomKey.trim();
    if (!state.containsKey(key)) return;
    state = Map<String, _Token>.from(state)..remove(key);
  }
}

class _Token {
  const _Token(this.value, this.expiresAt);
  final String value;
  final DateTime expiresAt;
}

final roomAccessTokenProvider =
    NotifierProvider<RoomAccessTokenNotifier, Map<String, _Token>>(
  RoomAccessTokenNotifier.new,
);
