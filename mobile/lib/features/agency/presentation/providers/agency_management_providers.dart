import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/agency_management_datasource.dart';
import '../../domain/entities/agency_management_models.dart';

final agencyManagementProvider = Provider<AgencyManagementDataSource>(
  (ref) => AgencyManagementDataSource(ref.watch(dioProvider)),
);

/// (sort, arama) → ajans listesi.
final agenciesListProvider =
    FutureProvider.autoDispose.family<List<AgencyCard>, (String, String)>((ref, args) {
  return ref.read(agencyManagementProvider).agencies(sort: args.$1, q: args.$2);
});

final agencyDetailProvider = FutureProvider.autoDispose.family<AgencyDetail, String>((ref, id) {
  return ref.read(agencyManagementProvider).agencyDetail(id);
});

final agencyPerformanceProvider =
    FutureProvider.autoDispose.family<AgencyPerformanceReport, String>((ref, period) {
  return ref.read(agencyManagementProvider).performance(period: period);
});

/// (userId, period) → yayıncı ayrıntısı.
final agencyMemberPerformanceProvider =
    FutureProvider.autoDispose.family<MemberPerformanceDetail, (String, String)>((ref, args) {
  return ref.read(agencyManagementProvider).memberPerformance(args.$1, period: args.$2);
});

final agencyJoinRequestsProvider = FutureProvider.autoDispose<List<JoinRequestView>>((ref) {
  return ref.read(agencyManagementProvider).joinRequests();
});

final agencyAccrualsProvider = FutureProvider.autoDispose<List<AccrualView>>((ref) {
  return ref.read(agencyManagementProvider).accruals();
});

final agencyAnnouncementsProvider = FutureProvider.autoDispose<(List<AgencyAnnouncement>, bool)>((ref) {
  return ref.read(agencyManagementProvider).announcements();
});

final agencyPromisesProvider = FutureProvider.autoDispose<AgencyPromisesData>((ref) {
  return ref.read(agencyManagementProvider).promises();
});

final agencyStaffProvider = FutureProvider.autoDispose<List<StaffEntry>>((ref) {
  return ref.read(agencyManagementProvider).staff();
});

final broadcasterPanelProvider = FutureProvider.autoDispose<BroadcasterPanel>((ref) {
  return ref.read(agencyManagementProvider).broadcasterPanel();
});

final agencyRosterProvider = FutureProvider.autoDispose<AgencyRoster>((ref) {
  return ref.read(agencyManagementProvider).roster();
});

final adminAgencyPromisesProvider = FutureProvider.autoDispose.family<List<AdminPromiseVersion>, String>((ref, status) {
  return ref.read(agencyManagementProvider).adminPromises(status: status);
});

final adminAgencyAlertsProvider = FutureProvider.autoDispose.family<List<AgencyAlertView>, int>((ref, days) {
  return ref.read(agencyManagementProvider).adminAlerts(days: days);
});

/// (agencyId, period) → performans satırları.
final adminAgencyPerformanceProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, (String, String)>((ref, args) {
  return ref.read(agencyManagementProvider).adminPerformance(args.$1, period: args.$2);
});
