import 'package:cookie_jar/cookie_jar.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/loading_timeout.dart';
import '../../../../core/auth/session_user_cache.dart';
import '../../../../core/network/cookie_jar_provider.dart';
import '../../../../core/network/token_storage.dart';
import '../../data/datasources/auth_service.dart';
import '../../data/models/auth_response.dart';
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
    this._authService,
    this._tokens,
    this._cookieJar,
    this._sessionCache,
  );

  final AuthRemoteDataSource _remote;
  final NativeAuthDataSource _native;
  final AuthService _authService;
  final TokenStorage _tokens;
  final CookieJar _cookieJar;
  final SessionUserCache _sessionCache;

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
      for (final entry in Map.from(dm).entries) {
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
      final um = _userMap(body);
      await _tokens.writeTokens(
        access: access,
        refresh: refresh,
        userId: um?['id']?.toString(),
      );
    }
    final um = _userMap(body);
    if (um != null) {
      final merged = _mergeRoleHints(um, body);
      final dto = UserDto.fromJson(merged);
      final entity = dto.toEntity(role: dto.roleFrom(merged), source: merged);
      await _sessionCache.write(entity);
      return entity;
    }
    final me = await _remote.me();
    final um2 = _userMap(me) ?? me;
    final merged2 = _mergeRoleHints(um2, me);
    final dto = UserDto.fromJson(merged2);
    final entity = dto.toEntity(role: dto.roleFrom(merged2), source: merged2);
    await _sessionCache.write(entity);
    return entity;
  }

  Future<UserEntity> _mapAuthResponse(AuthResponse response) async {
    final dto = UserDto.fromApiMap(response.user.toJson());
    final userJson = response.user.toJson();
    final entity = dto.toEntity(role: dto.roleFrom(userJson), source: userJson);
    await _sessionCache.write(entity);
    return entity;
  }

  @override
  Future<UserEntity> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _authService.login(
      email: identifier,
      password: password,
    );
    return _mapAuthResponse(response);
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
    final response = await _authService.register(
      name: displayName,
      email: email,
      password: password,
      username: username,
      birthDate: birthDate,
      birthTime: birthTime,
      preferredLanguage: language,
    );
    return _mapAuthResponse(response);
  }

  @override
  Future<UserEntity> loginWithGoogle() async {
    final body = await _native.signInWithGoogle();
    if (body.containsKey('accessToken') || body.containsKey('access_token')) {
      return _persistAndMap(body);
    }
    throw const ApiException('Google giriş yanıtı geçersiz');
  }

  @override
  Future<UserEntity> loginWithApple({String? referralCode}) async {
    final response = await _authService.signInWithApple(
      referralCode: referralCode,
    );
    return _mapAuthResponse(response);
  }

  @override
  Future<UserEntity> loginWithTikTok() async {
    final body = await _native.signInWithTikTok();
    if (body.containsKey('accessToken') || body.containsKey('access_token')) {
      return _persistAndMap(body);
    }
    throw const ApiException('TikTok giriş yanıtı geçersiz');
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
      final validated = await LoadingTimeout.run(
        _authService.validateSession(),
        timeout: const Duration(seconds: 8),
        message: 'Oturum doğrulanamadı',
      );
      if (validated == null) {
        await _sessionCache.clear();
        return null;
      }
      final dto = UserDto.fromApiMap(validated.toJson());
      final entity = dto.toEntity(
        role: dto.roleFrom(validated.toJson()),
        source: validated.toJson(),
      );
      await _sessionCache.write(entity);
      return entity;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _sessionCache.clear();
      } else {
        final cached = await _sessionCache.read();
        if (cached != null) return cached;
      }
      return null;
    } catch (_) {
      final cached = await _sessionCache.read();
      if (cached != null) return cached;
      return null;
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _authService.forgotPassword(email);
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
    await _authService.resetPassword(token: token, newPassword: password);
  }

  @override
  Future<void> logout() async {
    await _authService.logout();
    await _cookieJar.deleteAll();
    await _sessionCache.clear();
  }
}
