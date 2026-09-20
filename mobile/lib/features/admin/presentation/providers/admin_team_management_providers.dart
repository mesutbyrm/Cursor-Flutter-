import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';

/// Takım yönetimi - admin rolleri ve izinleri.
final adminTeamMembersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/team-members',
      query: {'limit': '100'},
    );
    if (res.data is List) {
      return List<Map<String, dynamic>>.from(
        (res.data as List).map((e) => e is Map ? e : {}),
      );
    }
    return [];
  } catch (e) {
    return [];
  }
});

/// Admin rolleri.
enum AdminRole {
  founder,          // Kurucu
  siteAdmin,        // Site Yöneticisi
  moderator,        // Moderatör
  supportStaff,     // Destek Personeli
  financial,        // Finans Yöneticisi
}

String adminRoleLabel(AdminRole role) {
  switch (role) {
    case AdminRole.founder:
      return 'Kurucu';
    case AdminRole.siteAdmin:
      return 'Site Yöneticisi';
    case AdminRole.moderator:
      return 'Moderatör';
    case AdminRole.supportStaff:
      return 'Destek Personeli';
    case AdminRole.financial:
      return 'Finans Yöneticisi';
  }
}

String adminRoleDescription(AdminRole role) {
  switch (role) {
    case AdminRole.founder:
      return 'Tam yetki - tüm sistem kontrolü';
    case AdminRole.siteAdmin:
      return 'Sistem yönetimi ve politika belirleme';
    case AdminRole.moderator:
      return 'İçerik ve kullanıcı moderasyonu';
    case AdminRole.supportStaff:
      return 'Kullanıcı desteği ve sorunlarını çözme';
    case AdminRole.financial:
      return 'Ödeme ve gelir yönetimi';
  }
}

/// Admin izinleri.
class AdminPermissions {
  final bool canManagePayments;
  final bool canModerateContent;
  final bool canManageUsers;
  final bool canManageAdmins;
  final bool canViewReports;
  final bool canAccessSystemSettings;
  final bool canViewActivityLog;
  final bool canManageLiveStreams;

  const AdminPermissions({
    this.canManagePayments = false,
    this.canModerateContent = false,
    this.canManageUsers = false,
    this.canManageAdmins = false,
    this.canViewReports = false,
    this.canAccessSystemSettings = false,
    this.canViewActivityLog = false,
    this.canManageLiveStreams = false,
  });

  factory AdminPermissions.fromRole(AdminRole role) {
    switch (role) {
      case AdminRole.founder:
        return const AdminPermissions(
          canManagePayments: true,
          canModerateContent: true,
          canManageUsers: true,
          canManageAdmins: true,
          canViewReports: true,
          canAccessSystemSettings: true,
          canViewActivityLog: true,
          canManageLiveStreams: true,
        );
      case AdminRole.siteAdmin:
        return const AdminPermissions(
          canManagePayments: true,
          canModerateContent: true,
          canManageUsers: true,
          canViewReports: true,
          canAccessSystemSettings: true,
          canViewActivityLog: true,
          canManageLiveStreams: true,
        );
      case AdminRole.moderator:
        return const AdminPermissions(
          canModerateContent: true,
          canManageUsers: true,
          canViewReports: true,
          canViewActivityLog: true,
        );
      case AdminRole.supportStaff:
        return const AdminPermissions(
          canManageUsers: true,
          canViewReports: true,
          canViewActivityLog: true,
        );
      case AdminRole.financial:
        return const AdminPermissions(
          canManagePayments: true,
          canViewReports: true,
          canViewActivityLog: true,
        );
    }
  }

  int get permissionCount {
    int count = 0;
    if (canManagePayments) count++;
    if (canModerateContent) count++;
    if (canManageUsers) count++;
    if (canManageAdmins) count++;
    if (canViewReports) count++;
    if (canAccessSystemSettings) count++;
    if (canViewActivityLog) count++;
    if (canManageLiveStreams) count++;
    return count;
  }
}

/// Takım üyesi aktiviteleri.
final adminTeamActivityProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final res = await dio.safeGet<dynamic>(
      '${ApiEndpoints.adminUsers}/team-activity',
      query: {'limit': '50'},
    );
    if (res.data is List) {
      return List<Map<String, dynamic>>.from(
        (res.data as List).map((e) => e is Map ? e : {}),
      );
    }
    return [];
  } catch (e) {
    return [];
  }
});
