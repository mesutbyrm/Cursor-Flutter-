import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/daily_task_entity.dart';

class DailyTasksRemoteDataSource {
  DailyTasksRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<DailyTaskEntity>> fetchDailyTasks() async {
    Object? lastError;
    for (final path in [
      ApiEndpoints.userDailyTasks,
      ApiEndpoints.dailyMissions,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(path);
        final list = _extractList(res.data);
        if (list.isNotEmpty) {
          return list
              .map((e) => DailyTaskEntity.fromJson(e))
              .where((t) => t.id.isNotEmpty)
              .toList();
        }
      } catch (e) {
        lastError = e;
      }
    }
    if (lastError != null) {
      if (lastError is ApiException) throw lastError;
      throw ApiException(ApiException.userMessage(lastError));
    }
    return const [];
  }

  Future<bool> claimTask(String taskId) async {
    for (final path in [
      ApiEndpoints.userDailyTasks,
      ApiEndpoints.dailyMissions,
    ]) {
      for (final body in [
        {'taskType': taskId},
        {'taskId': taskId, 'action': 'claim', 'id': taskId},
      ]) {
        try {
          await _dio.safePost<dynamic>(path, data: body);
          return true;
        } on ApiException catch (e) {
          final msg = e.message.toLowerCase();
          if (msg.contains('zaten') || msg.contains('already')) return true;
        } catch (_) {}
      }
    }
    return false;
  }

  /// Üretim: `POST /api/jeton` body `{ "action": "daily_login" }`
  Future<int?> claimJetonDailyLoginBonus() async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.jetonCatalog,
        data: const {'action': 'daily_login'},
      );
      final body = res.data;
      if (body is Map) {
        final m = Map<String, dynamic>.from(body);
        final bal = m['jetonBalance'] ?? m['newBalance'] ?? m['balance'];
        if (bal != null) return asInt(bal);
      }
      return 0;
    } catch (_) {
      return null;
    }
  }

  Future<bool> claimDailyLogin() async {
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.dailyLogin);
      return true;
    } catch (_) {
      try {
        await _dio.safePost<dynamic>(ApiEndpoints.homeDailyRewards);
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  Future<UserLevelEntity> fetchUserLevel() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.me);
      final body = res.data;
      if (body is Map) {
        return UserLevelEntity.fromJson(Map<String, dynamic>.from(body));
      }
    } catch (_) {}
    return const UserLevelEntity();
  }

  List<Map<String, dynamic>> _extractList(dynamic body) {
    if (body is List) {
      return body.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (body is Map) {
      final map = Map<String, dynamic>.from(body);
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : map;
      for (final key in [
        'tasks',
        'missions',
        'dailyTasks',
        'items',
        'list',
      ]) {
        final raw = data[key];
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }
    return const [];
  }
}
