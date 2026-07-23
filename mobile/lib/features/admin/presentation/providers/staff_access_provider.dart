import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/staff_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Site + oturumdan admin/yönetici yetkisi (`/api/user/credits` role veya kullanıcı adı).
class StaffAccess {
  const StaffAccess({
    required this.canManagePayments,
    required this.isSiteAdmin,
    required this.showAdminPanel,
    required this.canManageGifts,
    this.siteRole,
    this.username,
    this.isFounder = false,
  });

  final bool canManagePayments;
  final bool isSiteAdmin;
  final bool showAdminPanel;
  /// Hediye kataloğu CRUD — admin ve kurucu (yonetici).
  final bool canManageGifts;
  final String? siteRole;
  final String? username;
  /// Kurucu (yonetici) — admin atama/çıkarma dahil tam yetki.
  final bool isFounder;

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
    );
  }

  final walletRole = ref.watch(
    walletBalancesProvider.select((w) => w.valueOrNull?.role),
  );
  final wallet = ref.watch(walletBalancesProvider).valueOrNull;
  final authRole = user.role;
  final username = user.username.trim();
  final usernameLower = username.toLowerCase();

  // Kurucu / siteadmin nick — rol beklemeden tam yetki.
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
      siteRole: siteRole?.trim().isNotEmpty == true ? siteRole : 'admin',
      username: username,
      isFounder: usernameIsFounder,
    );
  }

  final canManagePayments = wallet?.canManagePayments == true ||
      wallet?.isAdmin == true ||
      usernameIsSiteAdmin ||
      StaffRoles.isAdminOrManager(role: siteRole, username: username);

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
  final isFounder =
      effectiveRole == 'yonetici' ||
      effectiveRole == 'yonetim' ||
      usernameLower == 'yonetici' ||
      usernameLower == 'yonetim';

  return StaffAccess(
    canManagePayments: canManagePayments,
    isSiteAdmin: isSiteAdmin,
    showAdminPanel: showAdminPanel,
    canManageGifts: canManageGifts,
    siteRole: effectiveRole,
    username: username,
    isFounder: isFounder,
  );
});
