import 'package:dio/dio.dart';

import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_provider.dart';
import '../core/util/json_util.dart';
import 'models/user_action_models.dart';
import 'service_utils.dart';

/// Kullanıcı engelleme ve şikayet — yeni mobil uçlar.
class UserService {
  UserService({required Dio Function() resolveAuthedDio})
      : _resolveAuthedDio = resolveAuthedDio;

  final Dio Function() _resolveAuthedDio;
  Dio get _dio => _resolveAuthedDio();

  /// `POST /api/user/block` — toggle (engelliyse kaldırır).
  Future<UserBlockResult> blockUser(String userId) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.userBlock,
        data: {'userId': userId.trim()},
      );
      final map = ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
      return UserBlockResult.fromJson(map);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      await _dio.safePost<dynamic>(
        ApiEndpoints.userBlocked,
        data: {'blockedUserId': userId.trim(), 'userId': userId.trim()},
      );
      return const UserBlockResult(
        success: true,
        blocked: true,
        message: 'Kullanıcı engellendi',
      );
    }
  }

  /// `GET /api/user/block`
  Future<List<BlockedUserEntry>> getBlockedUsers() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.userBlock);
      final list = ServiceUtils.extractList(
        res.data,
        keys: const ['data', 'users', 'items', 'blocked'],
      );
      return list
          .map(BlockedUserEntry.fromJson)
          .where((u) => u.userId.isNotEmpty)
          .toList(growable: false);
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.statusCode != 405) rethrow;
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.userBlocked);
      final list = ServiceUtils.extractList(
        res.data,
        keys: const ['data', 'users', 'items', 'blocked'],
      );
      return list
          .map(BlockedUserEntry.fromJson)
          .where((u) => u.userId.isNotEmpty)
          .toList(growable: false);
    }
  }

  /// `POST /api/user/report`
  Future<UserReportResult> reportUser({
    required String userId,
    required UserReportReason reason,
    String? details,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.userReport,
      data: {
        'userId': userId.trim(),
        'reason': reason.apiValue,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
    final map = ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
    return UserReportResult.fromJson(map);
  }
}
