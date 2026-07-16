import '../domain/entities/trtc_credentials.dart';

/// UserSig bellek içi önbellek — SDKSecret asla istemcide tutulmaz.
abstract final class TrtcSessionStore {
  static const defaultTtl = Duration(hours: 23);

  static TrtcCredentials? _credentials;
  static DateTime? _storedAt;
  static String? _roomId;

  static void put(TrtcCredentials credentials) {
    _credentials = credentials;
    _storedAt = DateTime.now();
    _roomId = credentials.roomId;
  }

  static TrtcCredentials? peek({String? roomId, Duration ttl = defaultTtl}) {
    final cred = _credentials;
    final at = _storedAt;
    if (cred == null || at == null) return null;
    if (DateTime.now().difference(at) > ttl) {
      clear();
      return null;
    }
    if (roomId != null &&
        roomId.trim().isNotEmpty &&
        !cred.matchesRoom(roomId)) {
      return null;
    }
    return cred;
  }

  static TrtcCredentials? take({String? roomId, Duration ttl = defaultTtl}) {
    final cred = peek(roomId: roomId, ttl: ttl);
    if (cred != null) clear();
    return cred;
  }

  static void clear() {
    _credentials = null;
    _storedAt = null;
    _roomId = null;
  }

  static String? get activeRoomId => _roomId;
}
