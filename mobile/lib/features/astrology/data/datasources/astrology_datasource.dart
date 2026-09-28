import 'package:dio/dio.dart';
import '../models/compatibility_dto.dart';
import '../../../../core/network/api_endpoints.dart';

abstract class AstrologyDataSource {
  Future<CompatibilityScoreDTO> getCompatibility(String sign1, String sign2);
  Future<DailyCompatibilityDTO> getDailyCompatibility(
    String sign1,
    String sign2,
    DateTime date,
  );
  Future<List<DailyCompatibilityDTO>> getWeeklyCompatibility(
    String sign1,
    String sign2,
  );
}

class AstrologyDataSourceImpl implements AstrologyDataSource {
  final Dio dio;

  AstrologyDataSourceImpl({required this.dio});

  @override
  Future<CompatibilityScoreDTO> getCompatibility(
    String sign1,
    String sign2,
  ) async {
    final response = await dio.post(
      ApiEndpoints.astrologyCompatibility,
      data: {
        'sign1': sign1.toLowerCase(),
        'sign2': sign2.toLowerCase(),
      },
    );
    return CompatibilityScoreDTO.fromJson(response.data);
  }

  @override
  Future<DailyCompatibilityDTO> getDailyCompatibility(
    String sign1,
    String sign2,
    DateTime date,
  ) async {
    final response = await dio.post(
      ApiEndpoints.astrologyDailyCompatibility,
      data: {
        'sign1': sign1.toLowerCase(),
        'sign2': sign2.toLowerCase(),
        'date': date.toIso8601String().split('T')[0],
      },
    );
    return DailyCompatibilityDTO.fromJson(response.data);
  }

  @override
  Future<List<DailyCompatibilityDTO>> getWeeklyCompatibility(
    String sign1,
    String sign2,
  ) async {
    final compatibility = <DailyCompatibilityDTO>[];
    final today = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = today.add(Duration(days: i));
      try {
        final daily = await getDailyCompatibility(sign1, sign2, date);
        compatibility.add(daily);
      } catch (_) {
        // Skip failed days
      }
    }

    return compatibility;
  }
}
