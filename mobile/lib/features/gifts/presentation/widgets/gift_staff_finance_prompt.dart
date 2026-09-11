import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../../core/auth/staff_roles.dart';
import '../../domain/gift_staff_finance_mode.dart';

/// Admin, kurucu veya yönetici hediye atarken finans modu sorulsun.
bool shouldAskGiftStaffFinanceMode(WidgetRef ref) {
  final access = ref.read(staffAccessProvider);
  if (access.isFounder || access.isSiteAdmin || access.canManageGifts) {
    return true;
  }
  final role = ref.read(walletBalancesProvider).valueOrNull?.role?.toLowerCase();
  if (role != null && StaffRoles.adminOrManager.contains(role)) {
    return true;
  }
  final authRole = ref.read(authControllerProvider).valueOrNull?.role?.toLowerCase();
  if (authRole != null && StaffRoles.adminOrManager.contains(authRole)) {
    return true;
  }
  final username =
      ref.read(authControllerProvider).valueOrNull?.username.toLowerCase();
  return username != null &&
      (StaffRoles.siteAdminUsernames.contains(username) ||
          StaffRoles.founderUsernames.contains(username));
}

/// `null` = kullanıcı iptal etti.
Future<GiftStaffFinanceMode?> showGiftStaffFinanceModeDialog(
  BuildContext context,
) async {
  return showDialog<GiftStaffFinanceMode>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Jeton türü'),
        content: const Text(
          'Bu hediye için hangi jeton türünü kullanmak istiyorsunuz?\n\n'
          '• Staff jeton: Alıcıya jeton düşmez (tanıtım / moderasyon).\n'
          '• Gerçek jeton: Alıcı normal şekilde kredilenir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, GiftStaffFinanceMode.staff),
            child: const Text('Staff jeton'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, GiftStaffFinanceMode.real),
            child: const Text('Gerçek jeton'),
          ),
        ],
      );
    },
  );
}

Future<GiftStaffFinanceMode?> resolveGiftStaffFinanceMode(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!shouldAskGiftStaffFinanceMode(ref)) return null;
  return showGiftStaffFinanceModeDialog(context);
}
