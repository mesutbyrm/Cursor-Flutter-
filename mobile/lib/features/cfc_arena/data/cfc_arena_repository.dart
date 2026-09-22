import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/cfc_arena_contest_filters.dart';

final cfcArenaRepositoryProvider = Provider<CfcArenaRepository>((ref) {
  return CfcArenaRepository(ref.watch(dioProvider));
});

class CfcArenaRepository {
  CfcArenaRepository(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchPublicContests() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.cfcArena);
    return parseCfcContestList(res.data);
  }

  Future<List<Map<String, dynamic>>> fetchAdminContests() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.adminCfcArena);
    return parseCfcContestList(res.data);
  }

  Future<void> adminMutate(Map<String, dynamic> body) async {
    await _dio.safePost<dynamic>(ApiEndpoints.adminCfcArena, data: body);
  }

  Future<void> joinContest(String contestId) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.cfcArenaJoin,
      data: {'contestId': contestId},
    );
  }
}
