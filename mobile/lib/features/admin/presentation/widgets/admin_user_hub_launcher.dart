import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/admin_user_permissions.dart';
import '../../domain/admin_user_util.dart';
import '../providers/staff_access_provider.dart';

/// Merkezi Kullanıcı Yönetim Merkezi — staff her yerden aynı rotayı açar (§40).
abstract final class AdminUserHubLauncher {
  static bool canOpen(StaffAccess access) =>
      AdminUserPermissions.canViewOverview(access);

  static void open(
    BuildContext context, {
    required String userId,
    Map<String, dynamic>? seedUser,
  }) {
    final id = userId.trim();
    if (id.isEmpty) return;
    context.push('/admin/users/$id');
  }

  static void openFromMap(BuildContext context, Map<String, dynamic> user) {
    final id = resolveAdminUserId(user);
    if (id.isEmpty) return;
    open(context, userId: id, seedUser: user);
  }

  /// Yetkili kullanıcıda uzun basınca komuta merkezi; diğerlerinde normal [onTap].
  static Widget wrap({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final access = ref.watch(staffAccessProvider);
    final canHub = canOpen(access) && userId.trim().isNotEmpty;
    if (!canHub) {
      if (onTap == null) return child;
      return GestureDetector(onTap: onTap, child: child);
    }
    return GestureDetector(
      onTap: onTap,
      onLongPress: () {
        open(context, userId: userId);
        onLongPress?.call();
      },
      child: child,
    );
  }
}
