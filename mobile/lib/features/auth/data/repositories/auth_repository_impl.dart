import 'package:cookie_jar/cookie_jar.dart';

import '../../../../core/network/loading_timeout.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/native_auth_datasource.dart';
import '../models/user_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remote,
    this._native,
    this._tokens,
    this._cookieJar,
  );

  final AuthRemoteDataSource _remote;
  final NativeAuthDataSource _native;
  final TokenStorage _tokens;
  final CookieJar _cookieJar;

  static String? _pickToken(Map<String, dynamic> m) {
    final v = m['accessToken'] ?? m['access_token'] ?? m['token'];
    return v is String ? v : null;
  }

  static String? _pickRefresh(Map<String, dynamic> m) {
    final v = m['refreshToken'] ?? m['refresh_token'];
    return v is String ? v : null;
  }

  static Map<String, dynamic>? _userMap(Map<String, dynamic> root) {
    final u = root['user'] ?? root['data'] ?? root['profile'];
    if (u is Map<String, dynamic>) return u;
    if (u is Map) return Map<String, dynamic>.from(u);
    if (root.containsKey('id') || root.containsKey('userId')) return root;
    return null;
  }

  Future<UserEntity> _persistAndMap(Map<String, dynamic> body) async {
    final access = _pickToken(body);
    final refresh = _pickRefresh(body);
    if (access != null) {
      await _tokens.writeTokens(access: access, refresh: refresh);
    }
    final um = _userMap(body);
    if (um != null) {
      final dto = UserDto.fromJson(um);
      return dto.toEntity(role: dto.roleFrom(um));
    }
    final me = await _remote.me();
    final um2 = _userMap(me) ?? me;
    final dto = UserDto.fromJson(um2);
    return dto.toEntity(role: dto.roleFrom(um2));
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    final body = await _remote.login(email: email, password: password);
    return _persistAndMap(body);
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String displayName,
    required String username,
    String? phone,
    String? birthDate,
    String? birthTime,
    String language = 'tr',
  }) async {
    final body = await _remote.register(
      email: email,
      password: password,
      displayName: displayName,
      username: username,
      phone: phone,
      birthDate: birthDate,
      birthTime: birthTime,
      language: language,
    );
    return _persistAndMap(body);
  }

  @override
  Future<UserEntity> loginWithGoogle() async {
    final body = await _native.signInWithGoogle();
    return _persistAndMap(body);
  }

  @override
  Future<UserEntity> loginWithTikTok() async {
    final body = await _native.signInWithTikTok();
    return _persistAndMap(body);
  }

  @override
  Future<UserEntity?> currentUser() async {
    final access = await _tokens.readAccess();
    if (access == null || access.isEmpty) return null;
    if (access == TokenStorage.sessionCookieMarker) {
      await _tokens.clear();
      return null;
    }
    try {
      final me = await LoadingTimeout.run(
        _remote.me(),
        timeout: const Duration(seconds: 8),
        message: 'Oturum doğrulanamadı',
      );
      final um = _userMap(me) ?? me;
      final dto = UserDto.fromJson(um);
      return dto.toEntity(role: dto.roleFrom(um));
    } catch (_) {
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _remote.requestPasswordReset(email);
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await _remote.resetPassword(token: token, password: password);
  }

  @override
  Future<void> logout() async {
    await _cookieJar.deleteAll();
    await _tokens.clear();
  }
}
