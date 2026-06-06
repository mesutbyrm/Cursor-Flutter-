import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/staff_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Site + oturumdan admin/yönetici yetkisi (`/api/user/credits` role veya kullanıcı adı).
class StaffAccess {
  const StaffAccess({
    required this.canManagePayments,
    this.siteRole,
  });

  final bool canManagePayments;
  final String? siteRole;

  String get roleLabel {
    if (siteRole != null && siteRole!.isNotEmpty) {
      return StaffRoles.labelTr(siteRole!);
    }
    return 'Yönetici';
  }
}

final staffAccessProvider = Provider<StaffAccess>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) {
    return const StaffAccess(canManagePayments: false);
  }

  final wallet = ref.watch(walletBalancesProvider);
  final siteRole = wallet.valueOrNull?.role;
  final username = user.username;

  final canManage = StaffRoles.isAdminOrManager(
    role: siteRole,
    username: username,
  );

  String? effectiveRole = siteRole?.trim().isNotEmpty == true
      ? siteRole!.toLowerCase().trim()
      : null;
  if (effectiveRole == null &&
      StaffRoles.managerUsernames.contains(username.toLowerCase().trim())) {
    effectiveRole = username.toLowerCase().trim();
  }

  return StaffAccess(
    canManagePayments: canManage,
    siteRole: effectiveRole,
  );
});
