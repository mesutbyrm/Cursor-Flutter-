import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';

class AchievementEntity {
  const AchievementEntity({
    required this.id,
    required this.title,
    this.description,
    this.icon,
    this.unlocked = false,
    this.progress,
  });

  final String id;
  final String title;
  final String? description;
  final String? icon;
  final bool unlocked;
  final int? progress;

  factory AchievementEntity.fromJson(Map<String, dynamic> json) {
    return AchievementEntity(
      id: pick(json, ['id', '_id', 'slug'])?.toString() ?? '',
      title: pick(json, ['title', 'name', 'label'])?.toString() ?? 'Rozet',
      description: pick(json, ['description', 'detail'])?.toString(),
      icon: pick(json, ['icon', 'emoji', 'badge'])?.toString(),
      unlocked: json['unlocked'] == true ||
          json['earned'] == true ||
          json['completed'] == true,
      progress: asInt(pick(json, ['progress', 'current'])),
    );
  }
}

class AchievementsRemoteDataSource {
  AchievementsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AchievementEntity>> fetchAchievements() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.userAchievements);
      final body = res.data;
      List<dynamic> raw = [];
      if (body is List) {
        raw = body;
      } else if (body is Map) {
        raw = asJsonList(
          pick(asJsonMap(body), ['achievements', 'items', 'data']) ?? [],
        );
      }
      return raw
          .whereType<Map>()
          .map((e) => AchievementEntity.fromJson(Map<String, dynamic>.from(e)))
          .where((a) => a.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
