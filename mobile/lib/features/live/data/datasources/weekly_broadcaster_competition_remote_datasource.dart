import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/pk/weekly_broadcaster_competition_models.dart';

class WeeklyBroadcasterCompetitionRemoteDataSource {
  const WeeklyBroadcasterCompetitionRemoteDataSource(this._dio);

  final Dio _dio;

  /// Haftalık yayıncı yarışması verilerini fetch eder.
  Future<WeeklyBroadcasterCompetition?> fetch() async {
    try {
      final res = await _dio.get<dynamic>(
        ApiEndpoints.weeklyBroadcasterCompetition,
      );
      if (res.data is! Map) return null;
      final json = asJsonMap(res.data);
      return WeeklyBroadcasterCompetition.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
