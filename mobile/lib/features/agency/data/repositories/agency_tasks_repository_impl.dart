import '../../domain/entities/agency_task_entity.dart';
import '../../domain/repositories/agency_tasks_repository.dart';
import '../datasources/agency_tasks_datasource.dart';

class AgencyTasksRepositoryImpl implements AgencyTasksRepository {
  final AgencyTasksDataSource _dataSource;

  AgencyTasksRepositoryImpl({required AgencyTasksDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<List<AgencyTask>> getAgencyTasks(String agencyId) async {
    final dtos = await _dataSource.getAgencyTasks(agencyId);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<AgencyTask> getTaskDetail(String taskId) async {
    final dto = await _dataSource.getTaskDetail(taskId);
    return dto.toDomain();
  }

  @override
  Future<AgencyTask> createTask({
    required String agencyId,
    required String title,
    required String description,
    required String taskType,
    required int reward,
    required DateTime dueDate,
  }) async {
    final dto = await _dataSource.createTask(
      agencyId: agencyId,
      title: title,
      description: description,
      taskType: taskType,
      reward: reward,
      dueDate: dueDate,
    );
    return dto.toDomain();
  }

  @override
  Future<void> assignTask(String taskId, List<String> userIds) async {
    await _dataSource.assignTask(taskId, userIds);
  }

  @override
  Future<void> updateTaskProgress(String taskId, int progress) async {
    await _dataSource.updateTaskProgress(taskId, progress);
  }

  @override
  Future<void> completeTask(String taskId, String? proofUrl) async {
    await _dataSource.completeTask(taskId, proofUrl);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _dataSource.deleteTask(taskId);
  }

  @override
  Future<List<AgencyMember>> getAgencyMembers(String agencyId) async {
    final dtos = await _dataSource.getAgencyMembers(agencyId);
    return dtos.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<AgencyMember> getMemberDetail(String memberId) async {
    final dto = await _dataSource.getMemberDetail(memberId);
    return dto.toDomain();
  }

  @override
  Future<void> inviteMember(String agencyId, String email) async {
    await _dataSource.inviteMember(agencyId, email);
  }

  @override
  Future<void> updateMemberRole(String memberId, String newRole) async {
    await _dataSource.updateMemberRole(memberId, newRole);
  }

  @override
  Future<void> removeMember(String memberId) async {
    await _dataSource.removeMember(memberId);
  }
}
