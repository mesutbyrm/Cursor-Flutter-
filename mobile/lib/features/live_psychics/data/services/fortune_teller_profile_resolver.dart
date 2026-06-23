import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/psychic_entity.dart';
import '../models/psychic_model.dart';
import '../repositories/live_psychics_remote_datasource.dart';
import '../../presentation/diagnostics/teller_role_diagnostic.dart';

/// Oturum açmış kullanıcı için falcı profili — tek kaynak.
///
/// **Asla** `GET /api/fortune-tellers/{authUser.id}` çağrılmaz;
/// `authUser.id` (userId) ≠ `fortuneTeller.id` (profil cuid).
class FortuneTellerProfileResolver {
  FortuneTellerProfileResolver(this._dio, this._psychics);

  final Dio _dio;
  final LivePsychicsRemoteDataSource _psychics;

  /// Sıra: my-profile → /api/me → /api/user/profile → liste (1 sayfa) → rol.
  Future<FortuneTellerProfileResult> resolveFortuneTellerProfile(
    UserEntity user,
  ) async {
    final authUserId = user.id.trim();
    if (authUserId.isEmpty) {
      return const FortuneTellerProfileResult(
        authUserId: '',
        source: 'no_auth_user',
      );
    }

    final rawMyProfile = await _psychics.fetchMyProfileRaw();
    var profile = PsychicModel.psychicFromMyProfileBody(rawMyProfile);
    if (profile != null && profile.id.trim().isNotEmpty) {
      return _result(
        profile: profile,
        authUserId: authUserId,
        source: 'my-profile',
        rawMyProfile: rawMyProfile,
      );
    }

    final fromMe = await _resolveFromMe(authUserId, user);
    if (fromMe.profile != null && fromMe.profile!.id.trim().isNotEmpty) {
      return _result(
        profile: fromMe.profile!,
        authUserId: authUserId,
        source: fromMe.source,
        rawMyProfile: rawMyProfile,
        rawMeSnippet: fromMe.rawMeSnippet,
      );
    }

    final fromSiteProfile = await _resolveFromSiteProfile(authUserId, user);
    if (fromSiteProfile.profile != null &&
        fromSiteProfile.profile!.id.trim().isNotEmpty) {
      return _result(
        profile: fromSiteProfile.profile!,
        authUserId: authUserId,
        source: fromSiteProfile.source,
        rawMyProfile: rawMyProfile,
        rawMeSnippet: fromMe.rawMeSnippet,
      );
    }

    profile = await _psychics.findTellerByAuthUserId(
      authUserId,
      maxPages: 1,
      pageLimit: 100,
    );
    if (profile != null && profile.id.trim().isNotEmpty) {
      return _result(
        profile: profile,
        authUserId: authUserId,
        source: 'fortune-tellers-list',
        rawMyProfile: rawMyProfile,
        rawMeSnippet: fromMe.rawMeSnippet,
      );
    }

    if (_roleLooksLikeTeller(user.role) ||
        fromMe.isFortuneTellerFlag ||
        fromSiteProfile.isFortuneTellerFlag) {
      final tellerId = fromMe.fortuneTellerId ??
          fromSiteProfile.fortuneTellerId ??
          authUserId;
      final synthetic = PsychicEntity(
        id: tellerId,
        userId: authUserId,
        name: user.display,
        applicationStatus: 'approved',
      );
      return _result(
        profile: synthetic,
        authUserId: authUserId,
        source: 'role-or-me-flag',
        rawMyProfile: rawMyProfile,
        rawMeSnippet: fromMe.rawMeSnippet,
      );
    }

    return FortuneTellerProfileResult(
      authUserId: authUserId,
      source: 'not_resolved',
      rawMyProfile: TellerRoleDiagnostic.truncateJson(rawMyProfile),
      rawMeSnippet: fromMe.rawMeSnippet,
    );
  }

  Future<
      ({
        PsychicEntity? profile,
        String source,
        String? rawMeSnippet,
        String? fortuneTellerId,
        bool isFortuneTellerFlag,
      })> _resolveFromMe(String authUserId, UserEntity user) async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.me);
      final rawMeSnippet = TellerRoleDiagnostic.truncateJson(res.data);
      final isFortuneTellerFlag = _meIndicatesFortuneTeller(res.data);
      final embedded = _parseTellerFromMeBody(res.data, authUserId);
      final tellerId = _fortuneTellerIdFromMeBody(res.data);
      if (embedded != null && embedded.id.trim().isNotEmpty) {
        return (
          profile: embedded,
          source: '/api/me',
          rawMeSnippet: rawMeSnippet,
          fortuneTellerId: tellerId ?? embedded.id,
          isFortuneTellerFlag: isFortuneTellerFlag,
        );
      }

      if (tellerId != null && tellerId.isNotEmpty) {
        final detail = await _psychics.fetchPsychic(tellerId);
        if (detail != null && detail.id.trim().isNotEmpty) {
          return (
            profile: detail,
            source: '/api/me→fortune-tellers/$tellerId',
            rawMeSnippet: rawMeSnippet,
            fortuneTellerId: tellerId,
            isFortuneTellerFlag: isFortuneTellerFlag,
          );
        }
      }

      if (isFortuneTellerFlag) {
        return (
          profile: PsychicEntity(
            id: tellerId ?? authUserId,
            userId: authUserId,
            name: user.display,
            applicationStatus: 'approved',
          ),
          source: '/api/me→isFortuneTeller',
          rawMeSnippet: rawMeSnippet,
          fortuneTellerId: tellerId,
          isFortuneTellerFlag: true,
        );
      }

      return (
        profile: null,
        source: '/api/me',
        rawMeSnippet: rawMeSnippet,
        fortuneTellerId: tellerId,
        isFortuneTellerFlag: isFortuneTellerFlag,
      );
    } catch (_) {
      return (
        profile: null,
        source: '/api/me',
        rawMeSnippet: null,
        fortuneTellerId: null,
        isFortuneTellerFlag: false,
      );
    }
  }

  Future<
      ({
        PsychicEntity? profile,
        String source,
        String? fortuneTellerId,
        bool isFortuneTellerFlag,
      })> _resolveFromSiteProfile(String authUserId, UserEntity user) async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.userSiteProfile);
      final body = res.data;
      if (body is! Map) {
        return (
          profile: null,
          source: '/api/user/profile',
          fortuneTellerId: null,
          isFortuneTellerFlag: false,
        );
      }
      final map = asJsonMap(body);
      if (map['error'] != null && map['success'] != true) {
        return (
          profile: null,
          source: '/api/user/profile',
          fortuneTellerId: null,
          isFortuneTellerFlag: false,
        );
      }

      final isFortuneTellerFlag = _meIndicatesFortuneTeller(body);
      final embedded = _parseTellerFromMeBody(body, authUserId);
      final tellerId = _fortuneTellerIdFromMeBody(body);
      if (embedded != null && embedded.id.trim().isNotEmpty) {
        return (
          profile: embedded,
          source: '/api/user/profile',
          fortuneTellerId: tellerId ?? embedded.id,
          isFortuneTellerFlag: isFortuneTellerFlag,
        );
      }

      if (tellerId != null && tellerId.isNotEmpty) {
        final detail = await _psychics.fetchPsychic(tellerId);
        if (detail != null && detail.id.trim().isNotEmpty) {
          return (
            profile: detail,
            source: '/api/user/profile→fortune-tellers/$tellerId',
            fortuneTellerId: tellerId,
            isFortuneTellerFlag: isFortuneTellerFlag,
          );
        }
      }

      if (isFortuneTellerFlag) {
        return (
          profile: PsychicEntity(
            id: tellerId ?? authUserId,
            userId: authUserId,
            name: user.display,
            applicationStatus: 'approved',
          ),
          source: '/api/user/profile→isFortuneTeller',
          fortuneTellerId: tellerId,
          isFortuneTellerFlag: true,
        );
      }

      return (
        profile: null,
        source: '/api/user/profile',
        fortuneTellerId: tellerId,
        isFortuneTellerFlag: isFortuneTellerFlag,
      );
    } catch (_) {
      return (
        profile: null,
        source: '/api/user/profile',
        fortuneTellerId: null,
        isFortuneTellerFlag: false,
      );
    }
  }

  bool _meIndicatesFortuneTeller(dynamic body) {
    if (body is! Map) return false;
    final map = asJsonMap(body);
    final layers = <Map<String, dynamic>>[];
    if (map['data'] is Map) layers.add(asJsonMap(map['data']));
    layers.add(map);
    for (final layer in layers) {
      if (layer['isFortuneTeller'] == true ||
          layer['isLiveFortuneTeller'] == true ||
          layer['canGoOnline'] == true) {
        return true;
      }
      final roles = layer['roles'];
      if (roles is List) {
        for (final r in roles) {
          if (_roleLooksLikeTeller(r?.toString())) return true;
        }
      }
      final role = layer['role']?.toString();
      if (_roleLooksLikeTeller(role)) return true;
    }
    return false;
  }

  PsychicEntity? _parseTellerFromMeBody(dynamic body, String authUserId) {
    if (body is! Map) return null;
    final map = asJsonMap(body);
    if (map['success'] == false && map['error'] != null) return null;
    if (map['error'] != null &&
        map['success'] != true &&
        map['teller'] == null &&
        map['fortuneTeller'] == null) {
      return null;
    }

    final layers = <Map<String, dynamic>>[];
    if (map['data'] is Map) layers.add(asJsonMap(map['data']));
    layers.add(map);

    for (final layer in layers) {
      for (final key in const [
        'teller',
        'fortuneTeller',
        'liveFortuneTeller',
        'fortuneTellerProfile',
        'liveFortuneTellerProfile',
      ]) {
        final nested = layer[key];
        if (nested is Map) {
          final parsed = PsychicModel.psychicFromJson(nested);
          if (parsed.id.trim().isNotEmpty) return parsed;
        }
      }
    }
    return null;
  }

  String? _fortuneTellerIdFromMeBody(dynamic body) {
    if (body is! Map) return null;
    final map = asJsonMap(body);
    final layers = <Map<String, dynamic>>[];
    if (map['data'] is Map) layers.add(asJsonMap(map['data']));
    layers.add(map);
    for (final layer in layers) {
      final id = pick(layer, [
        'fortuneTellerId',
        'liveFortuneTellerId',
        'tellerProfileId',
        'tellerId',
      ])?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
      for (final key in const ['teller', 'fortuneTeller', 'liveFortuneTeller']) {
        final nested = layer[key];
        if (nested is Map) {
          final nestedId = pick(asJsonMap(nested), ['id', 'tellerId'])?.toString();
          if (nestedId != null && nestedId.isNotEmpty) return nestedId;
        }
      }
    }
    return null;
  }

  bool _roleLooksLikeTeller(String? role) {
    final r = role?.trim().toLowerCase() ?? '';
    if (r.isEmpty) return false;
    return r.contains('teller') ||
        r.contains('fortune') ||
        r.contains('falc') ||
        r.contains('falci');
  }

  FortuneTellerProfileResult _result({
    required PsychicEntity profile,
    required String authUserId,
    required String source,
    dynamic rawMyProfile,
    String? rawMeSnippet,
  }) {
    return FortuneTellerProfileResult(
      profile: profile,
      authUserId: authUserId,
      source: source,
      rawMyProfile: TellerRoleDiagnostic.truncateJson(rawMyProfile),
      rawMeSnippet: rawMeSnippet,
    );
  }
}

class FortuneTellerProfileResult {
  const FortuneTellerProfileResult({
    this.profile,
    required this.authUserId,
    this.source = 'none',
    this.rawMyProfile,
    this.rawMeSnippet,
  });

  final PsychicEntity? profile;
  final String authUserId;
  final String source;
  final String? rawMyProfile;
  final String? rawMeSnippet;

  bool get profileFound => profile != null;
  String? get fortuneTellerId => profile?.id;
  bool get isUsable => profile?.isUsable == true;
  bool get isApprovedTeller => isUsable;
  bool get isFortuneTeller => isUsable;
}
