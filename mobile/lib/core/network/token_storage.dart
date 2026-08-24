import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _kAccess = 'jwt_access_token';
const _kRefresh = 'jwt_refresh_token';
const _kUserId = 'jwt_user_id';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  String? _memoryAccess;
  String? _memoryRefresh;
  String? _memoryUserId;
  var _accessHydrated = false;
  var _refreshHydrated = false;
  var _userIdHydrated = false;

  /// Dio hot path — bellekte varsa secure storage okumaz.
  String? peekAccess() => _memoryAccess;

  String? peekRefresh() => _memoryRefresh;

  String? peekUserId() => _memoryUserId;

  Future<String?> readAccess() async {
    if (_accessHydrated) return _memoryAccess;
    final value = await _storage.read(key: _kAccess);
    _memoryAccess = value;
    _accessHydrated = true;
    return value;
  }

  Future<String?> readRefresh() async {
    if (_refreshHydrated) return _memoryRefresh;
    final value = await _storage.read(key: _kRefresh);
    _memoryRefresh = value;
    _refreshHydrated = true;
    return value;
  }

  Future<String?> readUserId() async {
    if (_userIdHydrated) return _memoryUserId;
    final value = await _storage.read(key: _kUserId);
    _memoryUserId = value;
    _userIdHydrated = true;
    return value;
  }

  Future<void> writeTokens({
    required String access,
    String? refresh,
    String? userId,
  }) async {
    _memoryAccess = access;
    _accessHydrated = true;
    await _storage.write(key: _kAccess, value: access);
    if (refresh != null) {
      _memoryRefresh = refresh;
      _refreshHydrated = true;
      await _storage.write(key: _kRefresh, value: refresh);
    }
    if (userId != null && userId.isNotEmpty) {
      await writeUserId(userId);
    }
  }

  Future<void> writeUserId(String userId) async {
    if (userId.isEmpty) return;
    _memoryUserId = userId;
    _userIdHydrated = true;
    await _storage.write(key: _kUserId, value: userId);
  }

  Future<void> clear() async {
    _memoryAccess = null;
    _memoryRefresh = null;
    _memoryUserId = null;
    _accessHydrated = true;
    _refreshHydrated = true;
    _userIdHydrated = true;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUserId);
  }

  /// NextAuth modunda çerez oturumu varken [currentUser] bu değeri yazar.
  static const sessionCookieMarker = '__session_cookie__';
}
