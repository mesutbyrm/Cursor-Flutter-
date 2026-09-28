import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/gift_goal.dart';

/// Hediye hedefi uçları — `/api/gifts/goals`.
class GiftGoalRemoteDataSource {
  GiftGoalRemoteDataSource(this._dio);

  final Dio _dio;

  /// Yeni hedef oluştur.
  Future<GiftGoal?> createGoal({
    required String context,
    required String contextId,
    required String title,
    required int targetAmount,
    int? durationMinutes,
  }) async {
    final endsAt = durationMinutes != null && durationMinutes > 0
        ? DateTime.now().toUtc().add(Duration(minutes: durationMinutes))
        : null;
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.giftsGoals,
      data: {
        'context': context,
        'contextId': contextId,
        'roomId': contextId,
        'title': title,
        'targetAmount': targetAmount,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (endsAt != null) 'endsAt': endsAt.toIso8601String(),
      },
    );
    return _parseSingle(res.data);
  }

  /// Bir bağlamdaki hedefleri getir. Aktif olanı öne alır.
  Future<List<GiftGoal>> fetchGoals({
    required String context,
    required String contextId,
    String? status,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.giftsGoals,
      query: {
        'context': context,
        'contextId': contextId,
        if (status != null) 'status': status,
      },
    );
    final body = res.data;
    dynamic list = body;
    if (body is Map) {
      list = asJsonMap(body)['goals'] ?? asJsonMap(body)['data'] ?? body;
    }
    if (list is! List) return const [];
    final out = <GiftGoal>[];
    for (final e in list) {
      if (e is Map) out.add(GiftGoal.fromJson(asJsonMap(e)));
    }
    return out;
  }

  GiftGoal? _parseSingle(dynamic body) {
    if (body is Map) {
      final m = asJsonMap(body);
      final data = m['goal'] is Map ? asJsonMap(m['goal']) : m;
      return GiftGoal.fromJson(data);
    }
    return null;
  }

  /// Aktif hedefi sonlandır. Backend'de kapatma ucu yok (`/api/gifts/goals`
  /// yalnız GET/POST; `/{id}` ve `/{id}/close` yoktu) — hedef süresi dolunca
  /// sunucuda biter. İstek atılmaz.
  Future<void> closeGoal(String goalId) async {}
}
