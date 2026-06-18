import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/agency_entity.dart';

class AgencyRemoteDataSource {
  AgencyRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AgencyEntity?> fetchMyAgency() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.agencyMy);
      final body = res.data;
      if (body is! Map) return null;
      final map = asJsonMap(body);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      final agency = data['agency'] ?? data;
      if (agency is! Map) return null;
      return _mapAgency(asJsonMap(agency));
    } catch (_) {
      return null;
    }
  }

  Future<List<AgencyMemberEntity>> fetchMembers() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.agencyMembers);
      return _parseMemberList(res.data);
    } catch (_) {
      return const [];
    }
  }

  Future<List<AgencyEarningEntity>> fetchEarnings() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.agencyEarnings);
      return _parseEarningList(res.data);
    } catch (_) {
      return const [];
    }
  }

  Future<List<AgencyTaskEntity>> fetchTasks() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.agencyTasks);
      return _parseTaskList(res.data);
    } catch (_) {
      return const [];
    }
  }

  Future<bool> sendInvite(String userId) async {
    if (userId.trim().isEmpty) return false;
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.agencyInvite,
        data: {'userId': userId.trim()},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  AgencyEntity _mapAgency(Map<String, dynamic> m) {
    final user = asJsonMap(m['user'] ?? m['owner']);
    return AgencyEntity(
      id: _str(m, ['id', '_id', 'agencyId']) ?? '',
      name: _str(m, ['name', 'displayName', 'title']) ??
          _str(user, ['name', 'displayName']) ??
          'Ajans',
      description: _str(m, ['description', 'bio', 'about']),
      logoUrl: _str(m, ['logoUrl', 'logo', 'image', 'avatarUrl']),
      applicationStatus: _readApplicationStatus(m),
      memberCount: asInt(pick(m, ['memberCount', 'members', 'totalMembers'])),
      totalEarnings: asInt(
        pick(m, ['totalEarnings', 'earnings', 'total_earnings']),
      ),
      pendingEarnings: asInt(
        pick(m, ['pendingEarnings', 'pending', 'pendingBalance']),
      ),
      ownerUserId: _str(m, ['ownerId', 'ownerUserId', 'userId']) ??
          _str(user, ['id', 'userId']),
      inviteCode: _str(m, ['inviteCode', 'code', 'referralCode']),
      isActive: m['isActive'] == true ||
          m['active'] == true ||
          m['status']?.toString().toLowerCase() == 'active',
    );
  }

  String? _readApplicationStatus(Map<String, dynamic> m) {
    final direct = _str(m, ['applicationStatus', 'application_status']);
    if (direct != null) return direct;
    if (m['isApproved'] == true || m['approved'] == true) return 'approved';
    final status = _str(m, ['status']);
    if (status != null) {
      final lower = status.toLowerCase();
      const appStatuses = {'approved', 'pending', 'rejected', 'declined'};
      if (appStatuses.contains(lower)) return status;
    }
    return null;
  }

  String? _str(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return null;
  }

  List<AgencyMemberEntity> _parseMemberList(dynamic body) {
    final list = _extractList(body);
    return list.map((raw) {
      final m = asJsonMap(raw);
      final user = asJsonMap(m['user'] ?? m['profile']);
      return AgencyMemberEntity(
        id: _str(m, ['id', 'userId', 'memberId']) ??
            _str(user, ['id', 'userId']) ??
            '',
        name: _str(m, ['name', 'displayName']) ??
            _str(user, ['name', 'displayName', 'username']) ??
            'Üye',
        avatarUrl: _str(m, ['avatarUrl', 'image', 'avatar']) ??
            _str(user, ['avatarUrl', 'image']),
        role: _str(m, ['role', 'memberRole']),
        earnings: asInt(pick(m, ['earnings', 'totalEarnings', 'commission'])),
        isOnline: m['isOnline'] == true || m['online'] == true,
      );
    }).where((m) => m.id.isNotEmpty).toList(growable: false);
  }

  List<AgencyEarningEntity> _parseEarningList(dynamic body) {
    final list = _extractList(body);
    return list.map((raw) {
      final m = asJsonMap(raw);
      final user = asJsonMap(m['user'] ?? m['member']);
      return AgencyEarningEntity(
        id: _str(m, ['id', '_id']) ?? '',
        amount: asInt(pick(m, ['amount', 'earnings', 'jeton', 'total'])),
        source: _str(m, ['source', 'type', 'description']),
        createdAt: DateTime.tryParse(
          pick(m, ['createdAt', 'created_at', 'date'])?.toString() ?? '',
        ),
        memberName: _str(user, ['name', 'displayName', 'username']),
      );
    }).where((e) => e.id.isNotEmpty).toList(growable: false);
  }

  List<AgencyTaskEntity> _parseTaskList(dynamic body) {
    final list = _extractList(body);
    return list.map((raw) {
      final m = asJsonMap(raw);
      return AgencyTaskEntity(
        id: _str(m, ['id', '_id']) ?? '',
        title: _str(m, ['title', 'name']) ?? 'Görev',
        description: _str(m, ['description', 'details']),
        reward: asInt(pick(m, ['reward', 'jeton', 'amount'])),
        completed: m['completed'] == true || m['isCompleted'] == true,
        deadline: DateTime.tryParse(
          pick(m, ['deadline', 'dueDate', 'expiresAt'])?.toString() ?? '',
        ),
      );
    }).where((t) => t.id.isNotEmpty).toList(growable: false);
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return const [];
    final map = asJsonMap(body);
    final data = map['data'] is Map ? asJsonMap(map['data']) : map;
    final raw = data['items'] ??
        data['members'] ??
        data['earnings'] ??
        data['tasks'] ??
        data['results'] ??
        [];
    return raw is List ? raw : const [];
  }
}
