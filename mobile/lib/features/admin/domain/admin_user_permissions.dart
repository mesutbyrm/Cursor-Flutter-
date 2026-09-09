import '../presentation/providers/staff_access_provider.dart';

/// Admin kullanıcı komuta merkezi — sekme ve eylem yetkileri.
///
/// Backend her zaman son sözü söyler (403). Bu matris yalnızca mobil UI kapısıdır.
abstract final class AdminUserPermissions {
  /// Özet, üyelik süresi, online — moderatör+ okuyabilir.
  static bool canViewOverview(StaffAccess a) =>
      a.canManageUsers ||
      a.canManagePayments ||
      a.canModerate ||
      a.canViewReports;

  static bool canViewFinance(StaffAccess a) => a.canManagePayments;

  static bool canEditFinance(StaffAccess a) => a.canManagePayments;

  static bool canViewGifts(StaffAccess a) =>
      a.canManagePayments || a.canModerate || a.canManageGifts;

  static bool canViewBroadcasts(StaffAccess a) =>
      a.canManageLiveStreams || a.canManageVoiceRooms || a.canModerate;

  static bool canViewActivity(StaffAccess a) =>
      canViewOverview(a) || a.canViewReports;

  /// Rol / üyelik / ban — kullanıcı yönetimi.
  static bool canEditProfile(StaffAccess a) => a.canManageUsers;

  /// Admin / yönetici atama — yalnızca kurucu.
  static bool canAssignAdminRole(StaffAccess a) => a.isFounder;

  /// Moderatör / destek rolü — admin veya kurucu.
  static bool canAssignStaffRole(StaffAccess a) =>
      a.canManageUsers && (a.isFounder || a.isSiteAdmin);

  /// Canlı falcı onayı — finans yetkisi veya kurucu.
  static bool canManagePsychic(StaffAccess a) =>
      a.canManagePayments || a.isFounder;

  /// Yayın / oda açma bayrakları — kurucu veya tam admin.
  static bool canManageFeatureFlags(StaffAccess a) =>
      a.isFounder || (a.canManageUsers && a.isSiteAdmin);

  /// Kullanıcı adına oda açma — üretimde özel endpoint gerekir (Faz 2).
  static bool canImpersonateRoomCreate(StaffAccess a) => a.isFounder;

  static bool canBanUser(StaffAccess a) =>
      a.canModerate || a.canManageUsers;

  static bool canDeleteUser(StaffAccess a) => a.isFounder;
}
