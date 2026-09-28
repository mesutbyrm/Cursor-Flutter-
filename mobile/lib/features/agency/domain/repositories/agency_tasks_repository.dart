import '../entities/agency_task_entity.dart';

abstract class AgencyTasksRepository {
  Future<List<AgencyTask>> getAgencyTasks(String agencyId);
  Future<AgencyTask> getTaskDetail(String taskId);
  Future<AgencyTask> createTask({
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
  Future<List<AgencyMember>> getAgencyMembers(String agencyId);
  Future<AgencyMember> getMemberDetail(String memberId);
  Future<void> inviteMember(String agencyId, String email);
  Future<void> updateMemberRole(String memberId, String newRole);
  Future<void> removeMember(String memberId);
}
