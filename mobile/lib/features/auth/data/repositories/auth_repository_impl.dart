import 'package:cookie_jar/cookie_jar.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokens, this._cookieJar);

  final AuthRemoteDataSource _remote;
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
      return UserDto.fromJson(um).toEntity();
    }
    final me = await _remote.me();
    final um2 = _userMap(me) ?? me;
    return UserDto.fromJson(um2).toEntity();
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    if (Env.useNextAuth) {
      await _remote.login(email: email, password: password);
      await _tokens.writeTokens(
        access: TokenStorage.sessionCookieMarker,
        refresh: null,
      );
      final s = await _remote.session();
      final u = _userMap(s);
      if (u == null) {
        throw const ApiException('Oturum oluşturulamadı');
      }
      return UserDto.fromJson(u).toEntity();
    }
    final body = await _remote.login(email: email, password: password);
    return _persistAndMap(body);
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final body = await _remote.register(
      email: email,
      password: password,
      displayName: displayName,
    );
    return _persistAndMap(body);
  }

  @override
  Future<UserEntity?> currentUser() async {
    if (Env.useNextAuth) {
      try {
        final s = await _remote.session();
        final u = s['user'];
        if (u is Map) {
          return UserDto.fromJson(Map<String, dynamic>.from(u)).toEntity();
        }
        return null;
      } catch (_) {
        await logout();
        return null;
      }
    }
    final token = await _tokens.readAccess();
    if (token == null || token.isEmpty) return null;
    try {
      final me = await _remote.me();
      final um = AuthRepositoryImpl._userMap(me) ?? me;
      return UserDto.fromJson(um).toEntity();
    } catch (_) {
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<void> logout() async {
    if (Env.useNextAuth) {
      try {
        await _remote.signOutNextAuth();
      } catch (_) {
        // Oturum zaten kapalı olabilir
      }
      await _cookieJar.deleteAll();
    }
    await _tokens.clear();
  }
}
