import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/agency_remote_datasource.dart';
import '../../domain/entities/agency_entity.dart';
import '../../../shell/presentation/providers/role_panel_providers.dart';

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
    final agency = await ref.read(rolePanelResolverProvider).resolveAgency(user);
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
    this.error,
  });

  final AgencyEntity? agency;
  final List<AgencyMemberEntity> members;
  final List<AgencyEarningEntity> earnings;
  final List<AgencyTaskEntity> tasks;
  final bool loading;
  final String? lastApiLog;
  final String? error;

  AgencyDashboardState copyWith({
    AgencyEntity? agency,
    List<AgencyMemberEntity>? members,
    List<AgencyEarningEntity>? earnings,
    List<AgencyTaskEntity>? tasks,
    bool? loading,
    String? lastApiLog,
    String? error,
    bool clearError = false,
  }) {
    return AgencyDashboardState(
      agency: agency ?? this.agency,
      members: members ?? this.members,
      earnings: earnings ?? this.earnings,
      tasks: tasks ?? this.tasks,
      loading: loading ?? this.loading,
      lastApiLog: lastApiLog ?? this.lastApiLog,
      error: clearError ? null : (error ?? this.error),
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

    state = state.copyWith(loading: true, agency: agency, clearError: true);
    final remote = ref.read(agencyRemoteProvider);
    try {
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
    } catch (e) {
      state = AgencyDashboardState(
        agency: agency,
        loading: false,
        error: ApiException.userMessage(e),
      );
    }
  }
}

final agencyDashboardProvider =
    AutoDisposeNotifierProvider<AgencyDashboardNotifier, AgencyDashboardState>(
  AgencyDashboardNotifier.new,
);
