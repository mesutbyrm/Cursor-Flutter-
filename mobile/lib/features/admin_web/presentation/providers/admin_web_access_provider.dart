import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/staff_roles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// Mobil WebView admin paneli — yalnızca Admin / Süper Admin.
final adminWebAccessProvider = Provider<bool>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null) return false;

  final wallet = ref.watch(walletBalancesProvider).valueOrNull;
  final role = wallet?.role?.trim().isNotEmpty == true
      ? wallet!.role
      : user.role;

  return StaffRoles.isStrictWebAdmin(
    role: role,
    username: user.username,
    walletIsAdmin: wallet?.isAdmin,
  );
});
