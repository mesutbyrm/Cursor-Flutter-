import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../models/agency_task_dto.dart';

abstract class AgencyTasksDataSource {
  Future<List<AgencyTaskDTO>> getAgencyTasks(String agencyId);
  Future<AgencyTaskDTO> getTaskDetail(String taskId);
  Future<AgencyTaskDTO> createTask({
    required String agencyId,
    required String title,
    required String description,
    required String taskType,
    required int reward,
    required DateTime dueDate,
  });
  Future<void> assignTask(String taskId, List<String> userIds);
  Future<void> updateTaskProgress(String taskId, int progress);
  Future<void> completeTask(String taskId, String? proofUrl);
  Future<void> deleteTask(String taskId);
  Future<List<AgencyMemberDTO>> getAgencyMembers(String agencyId);
  Future<AgencyMemberDTO> getMemberDetail(String memberId);
  Future<void> inviteMember(String agencyId, String email);
  Future<void> updateMemberRole(String memberId, String newRole);
  Future<void> removeMember(String memberId);
}

class AgencyTasksDataSourceImpl implements AgencyTasksDataSource {
  final Dio _dio;

  AgencyTasksDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<AgencyTaskDTO>> getAgencyTasks(String agencyId) async {
    final res = await _dio.safeGet<dynamic>(
      '${ApiEndpoints.agencyTasks}?agencyId=$agencyId',
    );
    final data = asJsonMap(res.data);
    final tasks = (data['tasks'] as List<dynamic>?)
            ?.map((e) => AgencyTaskDTO.fromJson(
                e is Map<String, dynamic> ? e : asJsonMap(e)))
            .toList() ??
        [];
    return tasks;
  }

  @override
  Future<AgencyTaskDTO> getTaskDetail(String taskId) async {
    final res = await _dio.safeGet<dynamic>(
      '${ApiEndpoints.agencyTasks}/$taskId',
    );
    final data = asJsonMap(res.data);
    return AgencyTaskDTO.fromJson(data);
  }

  @override
  Future<AgencyTaskDTO> createTask({
    required String agencyId,
    required String title,
    required String description,
    required String taskType,
    required int reward,
    required DateTime dueDate,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.agencyTasks,
      data: {
        'agencyId': agencyId,
        'title': title,
        'description': description,
        'taskType': taskType,
        'reward': reward,
        'dueDate': dueDate.toIso8601String(),
      },
    );
    final data = asJsonMap(res.data);
    return AgencyTaskDTO.fromJson(data);
  }

  @override
  Future<void> assignTask(String taskId, List<String> userIds) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.agencyTasks}/$taskId/assign',
      data: {'userIds': userIds},
    );
  }

  @override
  Future<void> updateTaskProgress(String taskId, int progress) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.agencyTasks}/$taskId/progress',
      data: {'progress': progress.clamp(0, 100)},
    );
  }

  @override
  Future<void> completeTask(String taskId, String? proofUrl) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.agencyTasks}/$taskId/complete',
      data: {'completionProof': proofUrl},
    );
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _dio.safeDelete<dynamic>(
      '${ApiEndpoints.agencyTasks}/$taskId',
    );
  }

  @override
  Future<List<AgencyMemberDTO>> getAgencyMembers(String agencyId) async {
    final res = await _dio.safeGet<dynamic>(
      '${ApiEndpoints.agencyMembers}?agencyId=$agencyId',
    );
    final data = asJsonMap(res.data);
    final members = (data['members'] as List<dynamic>?)
            ?.map((e) => AgencyMemberDTO.fromJson(
                e is Map<String, dynamic> ? e : asJsonMap(e)))
            .toList() ??
        [];
    return members;
  }

  @override
  Future<AgencyMemberDTO> getMemberDetail(String memberId) async {
    final res = await _dio.safeGet<dynamic>(
      '${ApiEndpoints.agencyMembers}/$memberId',
    );
    final data = asJsonMap(res.data);
    return AgencyMemberDTO.fromJson(data);
  }

  @override
  Future<void> inviteMember(String agencyId, String email) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.agencyInvite,
      data: {'agencyId': agencyId, 'email': email},
    );
  }

  @override
  Future<void> updateMemberRole(String memberId, String newRole) async {
    await _dio.safePost<dynamic>(
      '${ApiEndpoints.agencyMembers}/$memberId/role',
      data: {'role': newRole},
    );
  }

  @override
  Future<void> removeMember(String memberId) async {
    await _dio.safeDelete<dynamic>(
      '${ApiEndpoints.agencyMembers}/$memberId',
    );
  }
}
