import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/referral_entities.dart';

class ReferralRemoteDataSource {
  ReferralRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ReferralStatsEntity> fetchStats() async {
    final fromCanonical = await _tryGetMap(ApiEndpoints.referral);
    if (fromCanonical != null) {
      return _parseStats(fromCanonical);
    }
    for (final path in [ApiEndpoints.referralStats, ApiEndpoints.referralMe]) {
      final map = await _tryGetMap(path);
      if (map != null) return _parseStats(map);
    }
    return const ReferralStatsEntity(referralCode: '', shareUrl: '');
  }

  Future<List<ReferralUserEntity>> fetchUsers() async {
    final root = await _tryGetMap(ApiEndpoints.referral);
    if (root != null) {
      final fromRoot = _parseUsersList(root);
      if (fromRoot.isNotEmpty) return fromRoot;
    }
    final legacy = await _tryGetMap(ApiEndpoints.referralUsers);
    if (legacy != null) {
      return _parseUsersList(legacy);
    }
    return const [];
  }

  Future<ReferralStatsEntity> fetchEarnings() async {
    final economy = await _tryGetMap(
      ApiEndpoints.userReferralEarnings,
      query: {'limit': 25, 'offset': 0},
    );
    if (economy != null) {
      final stats = await fetchStats();
      final summary = economy['summary'] is Map
          ? asJsonMap(economy['summary'])
          : economy;
      return ReferralStatsEntity(
        referralCode: stats.referralCode,
        shareUrl: stats.shareUrl,
        headline: stats.headline,
        rewardHint: stats.rewardHint,
        invitedCount: stats.invitedCount,
        activeReferralCount: stats.activeReferralCount,
        totalEarnings: asInt(pick(summary, ['total', 'totalEarnings', 'totalCommission'])),
        monthEarnings: asInt(pick(summary, ['thisMonth', 'monthEarnings', 'monthCommission'])),
        pendingEarnings: asInt(pick(summary, ['pending', 'pendingEarnings'])),
        availableEarnings: asInt(pick(summary, ['available', 'availableEarnings'])),
        reversedEarnings: asInt(pick(summary, ['reversed', 'reversedEarnings'])),
        cappedEarnings: asInt(pick(summary, ['capped', 'cappedEarnings'])),
        lifetimeEarnings: asInt(pick(summary, ['lifetime', 'lifetimeEarnings'])),
        monthlyLimit: asInt(pick(summary, ['monthlyLimit'])),
        lifetimeLimit: asInt(pick(summary, ['lifetimeLimit'])),
      );
    }

    final legacy = await _tryGetMap(ApiEndpoints.referralEarnings);
    if (legacy != null) {
      final stats = await fetchStats();
      final data = legacy['data'] is Map ? asJsonMap(legacy['data']) : legacy;
      return ReferralStatsEntity(
        referralCode: stats.referralCode,
        shareUrl: stats.shareUrl,
        headline: stats.headline,
        rewardHint: stats.rewardHint,
        invitedCount: stats.invitedCount,
        activeReferralCount: stats.activeReferralCount,
        totalEarnings: asInt(pick(data, ['total', 'totalEarnings'])),
        monthEarnings: asInt(pick(data, ['thisMonth', 'monthEarnings'])),
        pendingEarnings: asInt(pick(data, ['pending', 'pendingEarnings'])),
        availableEarnings: asInt(pick(data, ['available', 'availableEarnings'])),
        reversedEarnings: asInt(pick(data, ['reversed', 'reversedEarnings'])),
        cappedEarnings: asInt(pick(data, ['capped', 'cappedEarnings'])),
        lifetimeEarnings: asInt(pick(data, ['lifetime', 'lifetimeEarnings'])),
        monthlyLimit: asInt(pick(data, ['monthlyLimit'])),
        lifetimeLimit: asInt(pick(data, ['lifetimeLimit'])),
      );
    }

    return fetchStats();
  }

  Future<List<ReferralLedgerEntryEntity>> fetchLedger({int limit = 50}) async {
    final economy = await _tryGetMap(
      ApiEndpoints.userReferralEarnings,
      query: {'limit': limit, 'offset': 0},
    );
    if (economy != null) {
      final items = economy['items'];
      if (items is List && items.isNotEmpty) {
        return items
            .whereType<Map>()
            .map((m) => _parseLedgerFromCommission(asJsonMap(m)))
            .toList();
      }
    }

    final legacy = await _tryGetMap(
      ApiEndpoints.referralLedger,
      query: {'limit': limit},
    );
    if (legacy != null) {
      return _parseLedgerList(legacy);
    }
    return const [];
  }

  Future<Map<String, dynamic>?> _tryGetMap(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(path, query: query);
      final body = res.data;
      if (body is! Map) return null;
      return asJsonMap(body);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }

  List<ReferralUserEntity> _parseUsersList(Map<String, dynamic> map) {
    final data = map['data'] is Map ? asJsonMap(map['data']) : map;
    final list = data['referrals'] ?? data['users'] ?? data['items'] ?? [];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => _parseUser(asJsonMap(m)))
        .toList();
  }

  List<ReferralLedgerEntryEntity> _parseLedgerList(Map<String, dynamic> map) {
    final data = map['data'] is Map ? asJsonMap(map['data']) : map;
    final list = data['items'] ?? data['ledger'] ?? [];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => _parseLedger(asJsonMap(m)))
        .toList();
  }

  ReferralStatsEntity _parseStats(dynamic body) {
    final map = body is Map ? asJsonMap(body) : <String, dynamic>{};
    final data = map['data'] is Map ? asJsonMap(map['data']) : map;
    final code =
        pick(data, ['referralCode', 'code'])?.toString() ?? '';
    final share = pick(data, [
          'shareUrl',
          'inviteLink',
          'referralLink',
          'referralUrl',
        ])?.toString() ??
        '';
    return ReferralStatsEntity(
      referralCode: code,
      shareUrl: share,
      headline: pick(data, ['headline'])?.toString(),
      rewardHint: pick(data, ['rewardHint'])?.toString(),
      invitedCount: asInt(pick(data, ['invitedCount', 'inviteCount'])),
      activeReferralCount:
          asInt(pick(data, ['activeReferralCount'])),
      totalEarnings: asInt(pick(data, ['totalEarnings', 'referralCreditsEarned'])),
      monthEarnings: asInt(pick(data, ['monthEarnings'])),
      pendingEarnings: asInt(pick(data, ['pendingEarnings'])),
      availableEarnings: asInt(pick(data, ['availableEarnings'])),
      reversedEarnings: asInt(pick(data, ['reversedEarnings'])),
      cappedEarnings: asInt(pick(data, ['cappedEarnings'])),
      lifetimeEarnings: asInt(pick(data, ['lifetimeEarnings'])),
      monthlyLimit: asInt(pick(data, ['monthlyLimit'])),
      lifetimeLimit: asInt(pick(data, ['lifetimeLimit'])),
    );
  }

  ReferralUserEntity _parseUser(Map<String, dynamic> m) {
    return ReferralUserEntity(
      userId: pick(m, ['userId', 'id'])?.toString() ?? '',
      username: pick(m, ['username'])?.toString(),
      displayName: pick(m, ['displayName', 'name'])?.toString(),
      avatarUrl: pick(m, ['avatarUrl', 'image'])?.toString(),
      joinedAt: pick(m, ['joinedAt', 'createdAt'])?.toString() ?? '',
      status: pick(m, ['status', 'referralStatus'])?.toString() ?? 'active',
      eligibleJetonVolume: asInt(pick(m, ['eligibleJetonVolume'])),
      referralEarnings: asInt(pick(m, ['referralEarnings'])),
    );
  }

  ReferralLedgerEntryEntity _parseLedger(Map<String, dynamic> m) {
    return ReferralLedgerEntryEntity(
      id: pick(m, ['id'])?.toString() ?? '',
      referredUserId: pick(m, ['referredUserId'])?.toString() ?? '',
      sourceType: pick(m, ['sourceType'])?.toString() ?? '',
      grossJeton: asInt(pick(m, ['grossJeton'])),
      beneficiaryShare: asInt(pick(m, ['beneficiaryShare'])),
      referralCommission: asInt(pick(m, ['referralCommission'])),
      status: pick(m, ['status'])?.toString() ?? '',
      cappedAmount: asInt(pick(m, ['cappedAmount'])),
      createdAt: pick(m, ['createdAt'])?.toString() ?? '',
    );
  }

  ReferralLedgerEntryEntity _parseLedgerFromCommission(Map<String, dynamic> m) {
    return ReferralLedgerEntryEntity(
      id: pick(m, ['id'])?.toString() ?? '',
      referredUserId: pick(m, ['referredUserId', 'userId'])?.toString() ?? '',
      sourceType: pick(m, ['sourceType', 'type'])?.toString() ?? '',
      grossJeton: asInt(pick(m, ['grossJeton', 'amount'])),
      beneficiaryShare: asInt(pick(m, ['beneficiaryShare'])),
      referralCommission: asInt(pick(m, ['referralCommission', 'commission'])),
      status: pick(m, ['status'])?.toString() ?? '',
      cappedAmount: asInt(pick(m, ['cappedAmount'])),
      createdAt: pick(m, ['createdAt'])?.toString() ?? '',
    );
  }
}
