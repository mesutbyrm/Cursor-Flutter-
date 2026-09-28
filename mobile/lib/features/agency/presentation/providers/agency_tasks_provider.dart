import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/agency_tasks_datasource.dart';
import '../../data/repositories/agency_tasks_repository_impl.dart';
import '../../domain/entities/agency_task_entity.dart';
import '../../domain/repositories/agency_tasks_repository.dart';
import '../../../../core/providers/dio_provider.dart';

final agencyTasksDataSourceProvider = Provider<AgencyTasksDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AgencyTasksDataSourceImpl(dio: dio);
});

final agencyTasksRepositoryProvider = Provider<AgencyTasksRepository>((ref) {
  final dataSource = ref.watch(agencyTasksDataSourceProvider);
  return AgencyTasksRepositoryImpl(dataSource: dataSource);
});

final agencyTasksProvider = FutureProvider.family<List<AgencyTask>, String>(
  (ref, agencyId) async {
    final repository = ref.watch(agencyTasksRepositoryProvider);
    return repository.getAgencyTasks(agencyId);
  },
);

final taskDetailProvider = FutureProvider.family<AgencyTask, String>(
  (ref, taskId) async {
    final repository = ref.watch(agencyTasksRepositoryProvider);
    return repository.getTaskDetail(taskId);
  },
);

final agencyMembersProvider = FutureProvider.family<List<AgencyMember>, String>(
  (ref, agencyId) async {
    final repository = ref.watch(agencyTasksRepositoryProvider);
    return repository.getAgencyMembers(agencyId);
  },
);

final memberDetailProvider = FutureProvider.family<AgencyMember, String>(
  (ref, memberId) async {
    final repository = ref.watch(agencyTasksRepositoryProvider);
    return repository.getMemberDetail(memberId);
  },
);

final selectedAgencyIdProvider = StateProvider<String?>((ref) => null);

final creatingTaskProvider = StateProvider<bool>((ref) => false);

final selectedTaskProvider = StateProvider<AgencyTask?>((ref) => null);
