import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/parity_models.dart';

/// Web'de olup mobilde eksik olan uçların tek veri katmanı.
/// Tüm uçlar `docs/FLUTTER_ENTegrasyon_KILAVUZU.md` ve backend kaynağına göre.
class ParityApi {
  ParityApi(this._dio);

  final Dio _dio;

  // ── Destek ──────────────────────────────────────────────────────────────
  Future<List<SupportTicket>> supportTickets() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.supportTickets);
    return asJsonList(parityUnwrap(res.data)).map(SupportTicket.fromJson).toList();
  }

  Future<SupportTicket> supportTicket(String id) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.supportTicket(id));
    return SupportTicket.fromJson(asJsonMap(parityUnwrap(res.data)));
  }

  Future<SupportTicket> createSupportTicket({
    required String subject,
    required String message,
    required String category,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.supportTickets,
      data: {'subject': subject, 'message': message, 'category': category},
    );
    return SupportTicket.fromJson(asJsonMap(parityUnwrap(res.data)));
  }

  Future<void> replySupportTicket(String id, String body) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.supportTicketMessages(id),
      data: {'body': body},
    );
  }

  Future<void> closeSupportTicket(String id) async {
    await _dio.safePatch<dynamic>(
      ApiEndpoints.supportTicket(id),
      data: {'status': 'closed'},
    );
  }

  // ── İade ────────────────────────────────────────────────────────────────
  Future<List<RefundRequest>> refunds() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.refunds);
    final map = asJsonMap(res.data);
    return asJsonList(map['refunds'] ?? parityUnwrap(res.data))
        .map(RefundRequest.fromJson)
        .toList();
  }

  /// [storePurchase] true → Google Play / App Store satın alma kimliği,
  /// false → web ödeme (`Payment`) kimliği.
  Future<void> createRefund({
    required String referenceId,
    required String reason,
    bool storePurchase = false,
  }) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.refunds,
      data: {
        storePurchase ? 'storePurchaseId' : 'paymentId': referenceId,
        'reason': reason,
      },
    );
  }

  // ── Üyelik ──────────────────────────────────────────────────────────────
  Future<List<MembershipPlanInfo>> membershipPlans() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.membershipPlans);
    final map = asJsonMap(res.data);
    return asJsonList(map['plans'] ?? parityUnwrap(res.data))
        .map(MembershipPlanInfo.fromJson)
        .toList();
  }

  Future<MembershipComparison> membershipComparison() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.membershipsComparison);
    return MembershipComparison.fromJson(asJsonMap(parityUnwrap(res.data)));
  }

  /// `POST /api/memberships/gift` — jeton/CFC ile üyelik hediye eder.
  Future<String> giftMembership({
    required String planId,
    required String receiverId,
    required String paymentMethod,
    String? message,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.membershipsGift,
      data: {
        'planId': planId,
        'receiverId': receiverId,
        'paymentMethod': paymentMethod,
        if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      },
    );
    final m = asJsonMap(res.data)['message']?.toString();
    return (m == null || m.isEmpty) ? 'Üyelik hediye edildi' : m;
  }

  // ── Liderlik ────────────────────────────────────────────────────────────
  Future<LeaderboardResult> top100({
    required String scope,
    required String period,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.leaderboardsTop100,
      query: {'scope': scope, 'period': period, 'limit': 100},
    );
    final map = asJsonMap(res.data);
    final selfId = map['currentUserId']?.toString();
    final p = map['period'] is Map ? asJsonMap(map['period']) : const <String, dynamic>{};
    return LeaderboardResult(
      entries: asJsonList(map['entries'])
          .map((e) => LeaderboardEntry.fromTop100(e, selfId: selfId))
          .toList(),
      periodKey: p['periodKey']?.toString(),
      endTime: parityDate(p['endTime']),
      selfRank: map['currentUserRank'] == null ? null : asInt(map['currentUserRank']),
    );
  }

  Future<LeaderboardResult> vipLeaderboard({int limit = 50}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.vipLeaderboard,
      query: {'limit': limit},
    );
    final data = asJsonMap(parityUnwrap(res.data));
    final self = data['self'] is Map ? asJsonMap(data['self']) : null;
    return LeaderboardResult(
      entries: asJsonList(data['rows']).map(LeaderboardEntry.fromVip).toList(),
      selfRank: self == null ? null : asInt(self['rank']),
    );
  }

  Future<List<SupporterLevelRow>> mySupporterLevels() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.supporterLevels);
    return asJsonList(parityUnwrap(res.data)).map(SupporterLevelRow.fromJson).toList();
  }

  Future<List<SupporterLevelRow>> topSupporters(String broadcasterId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.supporterLevels,
      query: {'broadcasterId': broadcasterId},
    );
    return asJsonList(parityUnwrap(res.data)).map(SupporterLevelRow.fromJson).toList();
  }

  // ── Ham GET/POST (falcı paneli, ajans büyüme vb.) ───────────────────────
  Future<Map<String, dynamic>> rawMap(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.safeGet<dynamic>(path, query: query);
    return asJsonMap(parityUnwrap(res.data));
  }

  Future<List<Map<String, dynamic>>> rawList(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.safeGet<dynamic>(path, query: query);
    return asJsonList(parityUnwrap(res.data));
  }

  Future<void> rawPost(String path, Map<String, dynamic> body) async {
    await _dio.safePost<dynamic>(path, data: body);
  }
}
