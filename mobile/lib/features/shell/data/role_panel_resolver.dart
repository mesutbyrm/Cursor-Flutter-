import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../../agency/data/datasources/agency_remote_datasource.dart';
import '../../agency/domain/entities/agency_entity.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../live_psychics/data/services/fortune_teller_profile_resolver.dart';
import '../../live_psychics/domain/entities/psychic_entity.dart';
import '../../live_psychics/presentation/diagnostics/teller_role_diagnostic.dart';

/// Onaylı ajans; falcı çözümlemesi [FortuneTellerProfileResolver]'a delege edilir.
class RolePanelResolver {
  RolePanelResolver(
    this._dio,
    this._agency,
    this._fortuneTeller,
  );

  final Dio _dio;
  final AgencyRemoteDataSource _agency;
  final FortuneTellerProfileResolver _fortuneTeller;

  Future<PsychicEntity?> resolveTeller(UserEntity user) async {
    final result = await resolveTellerDetailed(user);
    return result.profile;
  }

  Future<TellerResolveResult> resolveTellerDetailed(UserEntity user) async {
    final resolved = await _fortuneTeller.resolveFortuneTellerProfile(user);
    return TellerResolveResult(
      profile: resolved.profile,
      source: resolved.source,
      rawMyProfile: resolved.rawMyProfile,
      rawMeSnippet: resolved.rawMeSnippet,
    );
  }

  Future<AgencyEntity?> resolveAgency(UserEntity user) async {
    final userId = user.id.trim();
    if (userId.isEmpty) return null;

    var agency = await _agency.fetchMyAgency();
    if (_usableAgency(agency)) return agency;

    for (final path in [ApiEndpoints.me, ApiEndpoints.userSiteProfile]) {
      agency = await _agencyFromPath(path);
      if (_usableAgency(agency)) return agency;
    }

    if (await _canAccessAgencyEndpoints()) {
      return AgencyEntity(
        id: userId,
        name: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Ajans',
        applicationStatus: 'approved',
        isActive: true,
        ownerUserId: userId,
      );
    }

    if (_roleLooksLikeAgency(user.role)) {
      return AgencyEntity(
        id: userId,
        name: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Ajans',
        applicationStatus: 'approved',
        isActive: true,
        ownerUserId: userId,
      );
    }

    return null;
  }

  Future<AgencyEntity?> _agencyFromPath(String path) async {
    try {
      final res = await _dio.safeGet<dynamic>(path);
      return _parseAgencyBody(res.data);
    } catch (_) {
      return null;
    }
  }

  AgencyEntity? _parseAgencyBody(dynamic body) {
    if (body is! Map) return null;
    final map = asJsonMap(body);
    if (map['success'] == false && map['error'] != null) return null;

    final layers = <Map<String, dynamic>>[];
    if (map['data'] is Map) layers.add(asJsonMap(map['data']));
    layers.add(map);

    for (final layer in layers) {
      for (final key in const [
        'agency',
        'myAgency',
        'liveAgency',
        'agencyProfile',
        'profile',
      ]) {
        final nested = layer[key];
        if (nested is Map) {
          final parsed = _agency.mapAgencyPublic(asJsonMap(nested));
          if (_usableAgency(parsed)) return parsed;
        }
      }
      if (_looksLikeAgencyMap(layer)) {
        final parsed = _agency.mapAgencyPublic(layer);
        if (_usableAgency(parsed)) return parsed;
      }
    }

    final role = pick(map, ['role', 'userRole'])?.toString().toLowerCase() ?? '';
    final agencyId = pick(map, ['agencyId', 'agency_id', 'liveAgencyId'])?.toString();
    if (_roleLooksLikeAgency(role) ||
        _rolesContainAgency(map['roles']) ||
        map['isAgency'] == true ||
        map['isAgencyOwner'] == true ||
        map['isAgencyAdmin'] == true ||
        (agencyId != null && agencyId.isNotEmpty)) {
      return AgencyEntity(
        id: agencyId?.isNotEmpty == true ? agencyId! : 'agency',
        name: pick(map, ['agencyName', 'name'])?.toString() ?? 'Ajans',
        applicationStatus: 'approved',
        isActive: true,
      );
    }
    return null;
  }

  Future<bool> _canAccessAgencyEndpoints() async {
    for (final path in [
      ApiEndpoints.agencyMembers,
      ApiEndpoints.agencyEarnings,
      ApiEndpoints.agencyTasks,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        if (!_looksLikeAuthorizedBody(res.data)) continue;
        return true;
      } catch (_) {}
    }
    return false;
  }

  bool _looksLikeAuthorizedBody(dynamic body) {
    if (body is List) return true;
    if (body is! Map) return false;
    final map = asJsonMap(body);
    if (map['success'] == false) return false;
    if (map['error'] != null && map['success'] != true) return false;
    if (map.containsKey('sessions') ||
        map.containsKey('members') ||
        map.containsKey('earnings') ||
        map.containsKey('tasks') ||
        map.containsKey('agency')) {
      return true;
    }
    if (map['data'] is List) return true;
    if (map['data'] is Map) return true;
    return map.isNotEmpty;
  }

  bool _looksLikeAgencyMap(Map<String, dynamic> m) {
    final id = pick(m, ['id', '_id', 'agencyId'])?.toString();
    if (id == null || id.isEmpty) return false;
    return m.containsKey('name') ||
        m.containsKey('memberCount') ||
        m.containsKey('inviteCode') ||
        m.containsKey('ownerId');
  }

  bool _rolesContainAgency(dynamic roles) {
    if (roles is! List) return false;
    for (final r in roles) {
      if (_roleLooksLikeAgency(r?.toString())) return true;
    }
    return false;
  }

  bool _roleLooksLikeAgency(String? role) {
    final r = role?.trim().toLowerCase() ?? '';
    if (r.isEmpty) return false;
    return r.contains('agency') || r.contains('ajans');
  }

  bool _usableAgency(AgencyEntity? agency) =>
      agency != null && agency.isUsable;
}
