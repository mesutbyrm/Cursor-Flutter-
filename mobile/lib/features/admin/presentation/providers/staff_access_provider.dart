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
    this.siteRole,
    this.username,
  });

  final bool canManagePayments;
  final bool isSiteAdmin;
  final bool showAdminPanel;
  final String? siteRole;
  final String? username;

  /// Profil / panel başlığı — kullanıcı adı öncelikli (`admin` → Site Admin, `yonetici` → Kurucu).
  String get roleLabel {
    final u = username?.toLowerCase().trim() ?? '';
    if (u == 'admin') return 'Site Admin';
    if (u == 'yonetici') return 'Kurucu';
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
    );
  }

  final walletRole = ref.watch(
    walletBalancesProvider.select((w) => w.valueOrNull?.role),
  );
  final wallet = ref.watch(walletBalancesProvider).valueOrNull;
  final authRole = user.role;
  final siteRole = walletRole?.trim().isNotEmpty == true ? walletRole : authRole;
  final username = user.username;

  final isSiteAdmin = wallet?.isAdmin == true ||
      StaffRoles.isSiteAdminUser(role: siteRole, username: username);

  final canManagePayments = isSiteAdmin ||
      wallet?.canManagePayments == true ||
      StaffRoles.isAdminOrManager(
        role: siteRole,
        username: username,
      );

  final showAdminPanel = StaffRoles.canAccessAdminPanel(
    role: siteRole,
    username: username,
    walletIsAdmin: wallet?.isAdmin,
  );

  String? effectiveRole = siteRole?.trim().isNotEmpty == true
      ? siteRole!.toLowerCase().trim()
      : null;
  if (effectiveRole == null &&
      StaffRoles.managerUsernames.contains(username.toLowerCase().trim())) {
    effectiveRole = username.toLowerCase().trim();
  }
  if (isSiteAdmin && effectiveRole == null) {
    effectiveRole = 'admin';
  }

  return StaffAccess(
    canManagePayments: canManagePayments,
    isSiteAdmin: isSiteAdmin,
    showAdminPanel: showAdminPanel,
    siteRole: effectiveRole,
    username: username,
  );
});
