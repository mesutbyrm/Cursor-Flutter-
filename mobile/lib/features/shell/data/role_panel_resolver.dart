import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../../agency/data/datasources/agency_remote_datasource.dart';
import '../../agency/domain/entities/agency_entity.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../home/data/datasources/home_remote_datasource.dart';
import '../../home/domain/entities/live_fortune_teller_entity.dart';

/// Onaylı falcı/ajans — birden fazla üretim uç noktasından çözümleme.
class RolePanelResolver {
  RolePanelResolver(
    this._dio,
    this._home,
    this._agency,
  );

  final Dio _dio;
  final HomeRemoteDataSource _home;
  final AgencyRemoteDataSource _agency;

  Future<LiveFortuneTellerEntity?> resolveTeller(UserEntity user) async {
    final userId = user.id.trim();
    if (userId.isEmpty) return null;

    var profile = await _home.fetchMyFortuneTellerProfile();
    if (_usable(profile)) return profile;

    for (final path in [
      ApiEndpoints.me,
      ApiEndpoints.userSiteProfile,
      ApiEndpoints.fortuneTeller(userId),
    ]) {
      profile = await _tellerFromPath(path, userId);
      if (_usable(profile)) return profile;
    }

    try {
      final tellers = await _home.fetchLiveFortuneTellers();
      for (final t in tellers) {
        if (t.userId == userId || t.id == userId) {
          if (_usable(t)) return t;
        }
      }
    } catch (_) {}

    if (await _canAccessTellerSessions()) {
      return LiveFortuneTellerEntity(
        id: userId,
        userId: userId,
        name: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.username,
        avatarUrl: user.avatarUrl,
        applicationStatus: 'approved',
        isOnline: true,
      );
    }

    if (_roleLooksLikeTeller(user.role)) {
      return LiveFortuneTellerEntity(
        id: userId,
        userId: userId,
        name: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : user.username,
        avatarUrl: user.avatarUrl,
        applicationStatus: 'approved',
      );
    }

    return null;
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

  Future<LiveFortuneTellerEntity?> _tellerFromPath(
    String path,
    String userId,
  ) async {
    try {
      final res = await _dio.safeGet<dynamic>(path);
      return _parseTellerBody(res.data, userId);
    } catch (_) {
      return null;
    }
  }

  Future<AgencyEntity?> _agencyFromPath(String path) async {
    try {
      final res = await _dio.safeGet<dynamic>(path);
      return _parseAgencyBody(res.data);
    } catch (_) {
      return null;
    }
  }

  LiveFortuneTellerEntity? _parseTellerBody(dynamic body, String userId) {
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
        'profile',
      ]) {
        final nested = layer[key];
        if (nested is Map) {
          final parsed = _home.parseLiveFortuneTeller(nested);
          if (_usable(parsed)) return parsed;
        }
      }
      if (_looksLikeTellerMap(layer)) {
        final parsed = _home.parseLiveFortuneTeller(layer);
        if (_usable(parsed)) return parsed;
      }
    }

    final role = pick(map, ['role', 'userRole'])?.toString().toLowerCase() ?? '';
    final tellerId = pick(map, [
      'fortuneTellerId',
      'tellerId',
      'liveFortuneTellerId',
    ])?.toString();
    if (_roleLooksLikeTeller(role) ||
        _rolesContainTeller(map['roles']) ||
        map['isFortuneTeller'] == true ||
        map['isLiveFortuneTeller'] == true ||
        map['canGoOnline'] == true) {
      final id = (tellerId != null && tellerId.isNotEmpty) ? tellerId : userId;
      return LiveFortuneTellerEntity(
        id: id,
        userId: userId,
        name: pick(map, ['name', 'displayName'])?.toString() ?? 'Falcı',
        applicationStatus: 'approved',
        isOnline: map['isOnline'] == true || map['online'] == true,
      );
    }
    return null;
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

  Future<bool> _canAccessTellerSessions() async {
    for (final path in [
      ApiEndpoints.fortuneTellerSessionsWithStatus('pending'),
      ApiEndpoints.fortuneTellerIncomingSessions,
      ApiEndpoints.fortuneTellerSessions,
      ApiEndpoints.fortuneTellerSessionsStream,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        if (!_looksLikeAuthorizedBody(res.data)) continue;
        return true;
      } catch (_) {}
    }
    return false;
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

  bool _looksLikeTellerMap(Map<String, dynamic> m) {
    final id = pick(m, ['id', '_id', 'tellerId'])?.toString();
    if (id == null || id.isEmpty) return false;
    return m.containsKey('userId') ||
        m.containsKey('displayName') ||
        m.containsKey('specialties') ||
        m.containsKey('isOnline') ||
        m.containsKey('pricePerMinute') ||
        m.containsKey('canGoOnline');
  }

  bool _looksLikeAgencyMap(Map<String, dynamic> m) {
    final id = pick(m, ['id', '_id', 'agencyId'])?.toString();
    if (id == null || id.isEmpty) return false;
    return m.containsKey('name') ||
        m.containsKey('memberCount') ||
        m.containsKey('inviteCode') ||
        m.containsKey('ownerId');
  }

  bool _roleLooksLikeTeller(String? role) {
    final r = role?.trim().toLowerCase() ?? '';
    if (r.isEmpty) return false;
    return r.contains('teller') ||
        r.contains('fortune') ||
        r.contains('falc') ||
        r.contains('falci') ||
        r.contains('advisor');
  }

  bool _roleLooksLikeAgency(String? role) {
    final r = role?.trim().toLowerCase() ?? '';
    if (r.isEmpty) return false;
    return r.contains('agency') || r.contains('ajans');
  }

  bool _usable(LiveFortuneTellerEntity? profile) =>
      profile != null && profile.isUsable;

  bool _usableAgency(AgencyEntity? agency) =>
      agency != null && agency.isUsable;
}
