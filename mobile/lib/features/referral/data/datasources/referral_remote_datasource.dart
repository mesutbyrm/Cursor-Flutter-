import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/referral_entities.dart';

class ReferralRemoteDataSource {
  ReferralRemoteDataSource(this._dio);

  final Dio _dio;

  Future<ReferralStatsEntity> fetchStats() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.referralStats);
    return _parseStats(res.data);
  }

  Future<List<ReferralUserEntity>> fetchUsers() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.referralUsers);
    final body = res.data;
    dynamic list;
    if (body is Map) {
      final map = asJsonMap(body);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      list = data['referrals'] ?? data['items'] ?? [];
    } else {
      list = const [];
    }
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((m) => _parseUser(asJsonMap(m)))
        .toList();
  }

  Future<ReferralStatsEntity> fetchEarnings() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.referralEarnings);
    final body = res.data;
    final map = body is Map ? asJsonMap(body) : <String, dynamic>{};
    final data = map['data'] is Map ? asJsonMap(map['data']) : map;
    final stats = await fetchStats();
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

  Future<List<ReferralLedgerEntryEntity>> fetchLedger({int limit = 50}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.referralLedger,
      query: {'limit': limit},
    );
    final body = res.data;
    dynamic list;
    if (body is Map) {
      final map = asJsonMap(body);
      final data = map['data'] is Map ? asJsonMap(map['data']) : map;
      list = data['items'] ?? [];
    } else {
      list = const [];
    }
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
}
