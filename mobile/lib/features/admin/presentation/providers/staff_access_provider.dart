import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/staff_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Site + oturumdan staff yetkileri (`/api/user/credits` + `/api/me`).
class StaffAccess {
  const StaffAccess({
    required this.canManagePayments,
    required this.isSiteAdmin,
    required this.showAdminPanel,
    required this.canManageGifts,
    required this.canManageSiteAnimations,
    required this.isStaffMember,
    required this.canModerate,
    required this.canManageVoiceRooms,
    required this.canManageLiveStreams,
    required this.canManageUsers,
    required this.canViewReports,
    required this.canManageNotifications,
    required this.isSupportStaff,
    this.siteRole,
    this.username,
    this.isFounder = false,
  });

  final bool canManagePayments;
  final bool isSiteAdmin;
  final bool showAdminPanel;
  /// Hediye kataloğu CRUD — admin ve kurucu (yonetici).
  final bool canManageGifts;
  /// Site animasyon kütüphanesi — admin / kurucu.
  final bool canManageSiteAnimations;
  /// Herhangi bir staff rolü (moderatör, destek, admin…).
  final bool isStaffMember;
  /// İçerik moderasyonu (raporlar, PK moderasyon).
  final bool canModerate;
  /// Site sesli oda ayarları ve oda listesi.
  final bool canManageVoiceRooms;
  /// Aktif yayın listesi ve moderasyon.
  final bool canManageLiveStreams;
  /// Kullanıcı arama / düzenleme.
  final bool canManageUsers;
  /// Aktivite raporları.
  final bool canViewReports;
  /// Admin ödeme bildirimleri.
  final bool canManageNotifications;
  /// Destek / yardım rolü.
  final bool isSupportStaff;
  final String? siteRole;
  final String? username;
  /// Kurucu (yonetici) — admin atama/çıkarma dahil tam yetki.
  final bool isFounder;

  /// Tam admin paneli (finans + dashboard) — yalnızca finans yetkisi olanlar.
  bool get hasFullAdminDashboard => canManagePayments && showAdminPanel;

  /// Yetkili profil girişi — staff ama tam admin değil.
  bool get showStaffProfileEntry =>
      isStaffMember && !hasFullAdminDashboard && (canModerate || isSupportStaff);

  /// Profil / panel başlığı — kullanıcı adı öncelikli (`admin` → Site Admin, `yonetici` → Kurucu).
  String get roleLabel {
    final u = username?.toLowerCase().trim() ?? '';
    if (u == 'admin') return 'Site Admin';
    if (u == 'siteadmin') return 'Site Admin';
    if (u == 'yonetici') return 'Kurucu';
    if (u == 'yonetim') return 'Yönetim';
    if (siteRole != null && siteRole!.isNotEmpty) {
      return StaffRoles.labelTr(siteRole!);
    }
    return isSiteAdmin ? 'Site Admin' : 'Yönetici';
  }
}

final staffAccessProvider = Provider<StaffAccess>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) {
    return const StaffAccess(
      canManagePayments: false,
      isSiteAdmin: false,
      showAdminPanel: false,
      canManageGifts: false,
      canManageSiteAnimations: false,
      isStaffMember: false,
      canModerate: false,
      canManageVoiceRooms: false,
      canManageLiveStreams: false,
      canManageUsers: false,
      canViewReports: false,
      canManageNotifications: false,
      isSupportStaff: false,
    );
  }

  final walletRole = ref.watch(
    walletBalancesProvider.select((w) => w.valueOrNull?.role),
  );
  final wallet = ref.watch(walletBalancesProvider).valueOrNull;
  final authRole = user.role;
  final username = user.username.trim();
  final usernameLower = username.toLowerCase();

  final usernameIsFounder =
      StaffRoles.founderUsernames.contains(usernameLower);
  final usernameIsSiteAdmin =
      StaffRoles.siteAdminUsernames.contains(usernameLower);

  final siteRole = walletRole?.trim().isNotEmpty == true
      ? walletRole
      : (authRole?.trim().isNotEmpty == true ? authRole : null);

  final walletIsAdmin = wallet?.isAdmin == true;

  // Sunucu admin rolü — tüm özellikler açık (web ile aynı).
  if (walletIsAdmin) {
    return StaffAccess(
      canManagePayments: true,
      isSiteAdmin: true,
      showAdminPanel: true,
      canManageGifts: true,
      canManageSiteAnimations: true,
      isStaffMember: true,
      canModerate: true,
      canManageVoiceRooms: true,
      canManageLiveStreams: true,
      canManageUsers: true,
      canViewReports: true,
      canManageNotifications: true,
      isSupportStaff: false,
      siteRole: siteRole?.trim().isNotEmpty == true ? siteRole : 'admin',
      username: username,
      isFounder: usernameIsFounder,
    );
  }

  final canManagePayments = StaffRoles.canManageFinance(
    role: siteRole,
    username: username,
    walletCanManagePayments: wallet?.canManagePayments,
    walletIsAdmin: wallet?.isAdmin,
  );

  final isSiteAdmin = usernameIsSiteAdmin ||
      StaffRoles.hasFullStaffAccess(
        role: siteRole,
        username: username,
        walletIsAdmin: wallet?.isAdmin == true,
      );

  final showAdminPanel = usernameIsSiteAdmin ||
      StaffRoles.canAccessAdminPanel(
        role: siteRole,
        username: username,
        walletIsAdmin: wallet?.isAdmin,
      );

  String? effectiveRole = siteRole?.trim().isNotEmpty == true
      ? siteRole!.toLowerCase().trim()
      : null;
  if (effectiveRole == null && usernameIsSiteAdmin) {
    effectiveRole = switch (usernameLower) {
      'siteadmin' || 'admin' => 'admin',
      'yonetim' => 'yonetim',
      _ => usernameLower,
    };
  }
  if (isSiteAdmin && effectiveRole == null) {
    effectiveRole = 'admin';
  }

  final canManageGifts = isSiteAdmin || canManagePayments;
  final canManageSiteAnimations = isSiteAdmin || usernameIsFounder;
  final isFounder =
      effectiveRole == 'yonetici' ||
      effectiveRole == 'yonetim' ||
      usernameLower == 'yonetici' ||
      usernameLower == 'yonetim';

  final isStaffMember = StaffRoles.isAnyStaff(
    role: effectiveRole,
    username: username,
    walletIsStaff: wallet?.isStaff,
    walletIsAdmin: wallet?.isAdmin,
  );

  final canModerate = StaffRoles.canModerateContent(
    role: effectiveRole,
    username: username,
    walletIsAdmin: wallet?.isAdmin,
    walletIsStaff: wallet?.isStaff,
  );

  final canManageVoiceRooms = StaffRoles.canManageVoiceRooms(
    role: effectiveRole,
    username: username,
    walletIsAdmin: wallet?.isAdmin,
  );

  final canManageLiveStreams = StaffRoles.canManageLiveStreams(
    role: effectiveRole,
    username: username,
    walletIsAdmin: wallet?.isAdmin,
  );

  final canManageUsers = StaffRoles.canManageUsers(
    role: effectiveRole,
    username: username,
    walletCanManagePayments: wallet?.canManagePayments,
    walletIsAdmin: wallet?.isAdmin,
  );

  final canViewReports = canManagePayments || canModerate;
  final canManageNotifications = canManagePayments;
  final isSupportStaff = StaffRoles.isSupportRole(effectiveRole);

  return StaffAccess(
    canManagePayments: canManagePayments,
    isSiteAdmin: isSiteAdmin,
    showAdminPanel: showAdminPanel,
    canManageGifts: canManageGifts,
    canManageSiteAnimations: canManageSiteAnimations,
    isStaffMember: isStaffMember,
    canModerate: canModerate,
    canManageVoiceRooms: canManageVoiceRooms,
    canManageLiveStreams: canManageLiveStreams,
    canManageUsers: canManageUsers,
    canViewReports: canViewReports,
    canManageNotifications: canManageNotifications,
    isSupportStaff: isSupportStaff,
    siteRole: effectiveRole,
    username: username,
    isFounder: isFounder,
  );
});
