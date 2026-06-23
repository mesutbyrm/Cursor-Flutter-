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

  /// Sıra: my-profile → liste (userId) → /api/me (gömülü / fortuneTellerId → detay).
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
    // my-profile oturum sahibine aittir — userId eşleşmesi şart değil.
    if (profile != null && profile.id.trim().isNotEmpty) {
      return _result(
        profile: profile,
        authUserId: authUserId,
        source: 'my-profile',
        rawMyProfile: rawMyProfile,
      );
    }

    profile = await _psychics.findTellerByAuthUserId(authUserId);
    if (profile != null && profile.id.trim().isNotEmpty) {
      return _result(
        profile: profile,
        authUserId: authUserId,
        source: 'fortune-tellers-list',
        rawMyProfile: rawMyProfile,
      );
    }

    String? rawMeSnippet;
    final fromMe = await _resolveFromMe(authUserId);
    rawMeSnippet = fromMe.rawMeSnippet;
    if (fromMe.profile != null && fromMe.profile!.id.trim().isNotEmpty) {
      return _result(
        profile: fromMe.profile!,
        authUserId: authUserId,
        source: fromMe.source,
        rawMyProfile: rawMyProfile,
        rawMeSnippet: rawMeSnippet,
      );
    }

    if (_roleLooksLikeTeller(user.role) || await _psychics.canAccessTellerPanel()) {
      final synthetic = PsychicEntity(
        id: fromMe.fortuneTellerId ?? authUserId,
        userId: authUserId,
        name: user.display,
        applicationStatus: 'approved',
      );
      return _result(
        profile: synthetic,
        authUserId: authUserId,
        source: 'role-or-endpoint-probe',
        rawMyProfile: rawMyProfile,
        rawMeSnippet: rawMeSnippet,
      );
    }

    return FortuneTellerProfileResult(
      authUserId: authUserId,
      source: 'not_resolved',
      rawMyProfile: TellerRoleDiagnostic.truncateJson(rawMyProfile),
      rawMeSnippet: rawMeSnippet,
    );
  }

  Future<
      ({
        PsychicEntity? profile,
        String source,
        String? rawMeSnippet,
        String? fortuneTellerId,
      })> _resolveFromMe(String authUserId) async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.me);
      final rawMeSnippet = TellerRoleDiagnostic.truncateJson(res.data);
      final embedded = _parseTellerFromMeBody(res.data, authUserId);
      final tellerId = _fortuneTellerIdFromMeBody(res.data);
      if (embedded != null && embedded.id.trim().isNotEmpty) {
        return (
          profile: embedded,
          source: '/api/me',
          rawMeSnippet: rawMeSnippet,
          fortuneTellerId: tellerId ?? embedded.id,
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
          );
        }
      }

      return (
        profile: null,
        source: '/api/me',
        rawMeSnippet: rawMeSnippet,
        fortuneTellerId: tellerId,
      );
    } catch (_) {
      return (
        profile: null,
        source: '/api/me',
        rawMeSnippet: null,
        fortuneTellerId: null,
      );
    }
  }

  PsychicEntity? _parseTellerFromMeBody(dynamic body, String authUserId) {
    if (body is! Map) return null;
    final map = asJsonMap(body);
    if (map['success'] == false && map['error'] != null) return null;

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
