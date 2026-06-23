import 'package:cookie_jar/cookie_jar.dart';

import '../../../../core/network/loading_timeout.dart';
import '../../../../core/network/token_storage.dart';
import '../../domain/entities/active_session_entity.dart';
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


  static Map<String, dynamic> _mergeRoleHints(
    Map<String, dynamic> userMap,
    Map<String, dynamic> root,
  ) {
    final merged = Map<String, dynamic>.from(userMap);
    for (final key in const [
      'role',
      'tier',
      'roles',
      'isFortuneTeller',
      'isLiveFortuneTeller',
      'canGoOnline',
      'isAgency',
      'isAgencyOwner',
      'isAgencyAdmin',
      'fortuneTellerId',
      'liveFortuneTellerId',
      'tellerId',
      'agencyId',
      'agency_id',
      'liveAgencyId',
      'fortuneTeller',
      'agency',
      'liveAgency',
      'myAgency',
    ]) {
      final value = root[key];
      if (value != null && merged[key] == null) {
        merged[key] = value;
      }
    }
    final data = root['data'];
    if (data is Map) {
      final dm = data is Map<String, dynamic>
          ? data
          : Map<String, dynamic>.from(data);
      for (final entry in dm.entries) {
        if (merged[entry.key] == null) {
          merged[entry.key] = entry.value;
        }
      }
    }
    return merged;
  }

  Future<UserEntity> _persistAndMap(Map<String, dynamic> body) async {
    final access = _pickToken(body);
    final refresh = _pickRefresh(body);
    if (access != null) {
      await _tokens.writeTokens(access: access, refresh: refresh);
    }
    final um = _userMap(body);
    if (um != null) {
      final merged = _mergeRoleHints(um, body);
      final dto = UserDto.fromJson(merged);
      return dto.toEntity(role: dto.roleFrom(merged));
    }
    final me = await _remote.me();
    final um2 = _userMap(me) ?? me;
    final merged2 = _mergeRoleHints(um2, me);
    final dto = UserDto.fromJson(merged2);
    return dto.toEntity(role: dto.roleFrom(merged2));
  }

  @override
  Future<UserEntity> login({
    required String identifier,
    required String password,
  }) async {
    final body = await _remote.login(identifier: identifier, password: password);
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
      final merged = _mergeRoleHints(um, me);
      final dto = UserDto.fromJson(merged);
      return dto.toEntity(role: dto.roleFrom(merged));
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
  Future<void> sendEmailVerification({String? email}) async {
    await _remote.sendEmailVerification(email: email);
  }

  @override
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _remote.verifyEmail(email: email, code: code);
  }

  @override
  Future<List<ActiveSessionEntity>> fetchActiveSessions() async {
    final rows = await _remote.fetchActiveSessions();
    return rows.map(ActiveSessionEntity.fromJson).toList(growable: false);
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await _remote.revokeSession(sessionId);
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
