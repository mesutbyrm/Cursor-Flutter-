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

  Future<String?> readAccess() => _storage.read(key: _kAccess);
  Future<String?> readRefresh() => _storage.read(key: _kRefresh);
  Future<String?> readUserId() => _storage.read(key: _kUserId);

  Future<void> writeTokens({
    required String access,
    String? refresh,
    String? userId,
  }) async {
    await _storage.write(key: _kAccess, value: access);
    if (refresh != null) {
      await _storage.write(key: _kRefresh, value: refresh);
    }
    if (userId != null && userId.isNotEmpty) {
      await writeUserId(userId);
    }
  }

  Future<void> writeUserId(String userId) async {
    if (userId.isEmpty) return;
    await _storage.write(key: _kUserId, value: userId);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUserId);
  }

  /// NextAuth modunda çerez oturumu varken [currentUser] bu değeri yazar.
  static const sessionCookieMarker = '__session_cookie__';
}
