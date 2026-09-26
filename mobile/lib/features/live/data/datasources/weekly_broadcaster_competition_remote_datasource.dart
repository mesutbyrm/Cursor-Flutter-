import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/pk/weekly_broadcaster_competition_models.dart';

class WeeklyBroadcasterCompetitionRemoteDataSource {
  const WeeklyBroadcasterCompetitionRemoteDataSource(this._dio);

  final Dio _dio;

  /// Haftalık yayıncı yarışması verilerini fetch eder.
  ///
  /// Yanıt üç biçimde gelebiliyor: düz gövde, `{success, data:{…}}` zarfı veya
  /// doğrudan katılımcı dizisi. Yalnızca düz Map kabul edildiğinde zarflı yanıt
  /// sessizce boş tabloya dönüşüyordu.
  Future<WeeklyBroadcasterCompetition?> fetch() async {
    try {
      final res = await _dio.get<dynamic>(
        ApiEndpoints.weeklyBroadcasterCompetition,
      );
      final root = res.data;
      if (root is List) {
        return WeeklyBroadcasterCompetition.fromJson({'participants': root});
      }
      if (root is! Map) return null;
      final map = asJsonMap(root);
      final inner = pick(map, ['data', 'competition', 'result']);
      return WeeklyBroadcasterCompetition.fromJson(
        inner is Map ? asJsonMap(inner) : map,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WeeklyCompetition] fetch failed: $e');
      }
      return null;
    }
  }
}
