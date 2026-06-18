import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/agency_remote_datasource.dart';
import '../../domain/entities/agency_entity.dart';

final agencyRemoteProvider = Provider<AgencyRemoteDataSource>((ref) {
  return AgencyRemoteDataSource(ref.watch(dioProvider));
});

class ApprovedAgencyState {
  const ApprovedAgencyState({
    this.agency,
    this.loading = false,
    this.checked = false,
  });

  final AgencyEntity? agency;
  final bool loading;
  final bool checked;

  bool get isApprovedAgency => agency?.isUsable == true;

  ApprovedAgencyState copyWith({
    AgencyEntity? agency,
    bool? loading,
    bool? checked,
    bool clearAgency = false,
  }) {
    return ApprovedAgencyState(
      agency: clearAgency ? null : (agency ?? this.agency),
      loading: loading ?? this.loading,
      checked: checked ?? this.checked,
    );
  }
}

class ApprovedAgencyNotifier extends Notifier<ApprovedAgencyState> {
  @override
  ApprovedAgencyState build() {
    ref.listen(authControllerProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user == null) {
        state = const ApprovedAgencyState(checked: true);
        return;
      }
      if (prev?.valueOrNull?.id != user.id) {
        unawaited(refresh());
      }
    });
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user != null) {
      Future.microtask(refresh);
    }
    return ApprovedAgencyState(loading: user != null);
  }

  Future<void> refresh() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      state = const ApprovedAgencyState(checked: true);
      return;
    }
    state = state.copyWith(loading: true);
    final agency = await ref.read(agencyRemoteProvider).fetchMyAgency();
    state = ApprovedAgencyState(
      agency: agency,
      loading: false,
      checked: true,
    );
  }
}

final approvedAgencyProvider =
    NotifierProvider<ApprovedAgencyNotifier, ApprovedAgencyState>(
  ApprovedAgencyNotifier.new,
);

class AgencyDashboardState {
  const AgencyDashboardState({
    this.agency,
    this.members = const [],
    this.earnings = const [],
    this.tasks = const [],
    this.loading = true,
    this.lastApiLog,
  });

  final AgencyEntity? agency;
  final List<AgencyMemberEntity> members;
  final List<AgencyEarningEntity> earnings;
  final List<AgencyTaskEntity> tasks;
  final bool loading;
  final String? lastApiLog;

  AgencyDashboardState copyWith({
    AgencyEntity? agency,
    List<AgencyMemberEntity>? members,
    List<AgencyEarningEntity>? earnings,
    List<AgencyTaskEntity>? tasks,
    bool? loading,
    String? lastApiLog,
  }) {
    return AgencyDashboardState(
      agency: agency ?? this.agency,
      members: members ?? this.members,
      earnings: earnings ?? this.earnings,
      tasks: tasks ?? this.tasks,
      loading: loading ?? this.loading,
      lastApiLog: lastApiLog ?? this.lastApiLog,
    );
  }
}

class AgencyDashboardNotifier extends AutoDisposeNotifier<AgencyDashboardState> {
  @override
  AgencyDashboardState build() {
    Future.microtask(refresh);
    return const AgencyDashboardState();
  }

  Future<void> refresh() async {
    final approved = ref.read(approvedAgencyProvider);
    var agency = approved.agency;
    if (agency == null) {
      await ref.read(approvedAgencyProvider.notifier).refresh();
      agency = ref.read(approvedAgencyProvider).agency;
    }
    if (agency == null || !agency.isUsable) {
      state = AgencyDashboardState(agency: agency, loading: false);
      return;
    }

    state = state.copyWith(loading: true, agency: agency);
    final remote = ref.read(agencyRemoteProvider);
    final members = await remote.fetchMembers();
    final earnings = await remote.fetchEarnings();
    final tasks = await remote.fetchTasks();
    state = AgencyDashboardState(
      agency: agency,
      members: members,
      earnings: earnings,
      tasks: tasks,
      loading: false,
      lastApiLog:
          'GET /api/agency/my · ${members.length} üye · ${earnings.length} kazanç',
    );
  }
}

final agencyDashboardProvider =
    AutoDisposeNotifierProvider<AgencyDashboardNotifier, AgencyDashboardState>(
  AgencyDashboardNotifier.new,
);
