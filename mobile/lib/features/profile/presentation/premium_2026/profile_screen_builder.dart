import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../../fortune/presentation/providers/fortune_access_providers.dart';
import '../../../live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../providers/profile_providers.dart';
import 'profile_membership_helpers.dart';
import 'profile_screen_state.dart';

/// Oturum kullanıcısından minimum profil durumu — ek API yok.
ProfileScreenState profileScreenStateFromUser(UserEntity user) {
  return ProfileScreenState(
    user: user,
    jeton: user.coinBalance,
  );
}

/// Cüzdan verisi geldiğinde birleştirilmiş durum.
ProfileScreenState buildProfileWalletState(
  ProfileScreenState base,
  WalletBalances? wallet,
) {
  final info = resolveProfileMembership(
    rawMembership: wallet?.membership,
    daysRemaining: wallet?.membershipDaysRemaining,
  );
  return base.copyWith(
    wallet: wallet,
    jeton: wallet?.jeton ?? base.jeton,
    cfc: wallet?.cfc ?? base.cfc,
    membership: info.displayMembership,
    membershipDays: wallet?.membershipDaysRemaining,
    isVip: info.isVip,
  );
}

/// Mevcut provider'lardan birleşik profil durumu (yenileme / tam yükleme).
ProfileScreenState buildProfileScreenState(WidgetRef ref, UserEntity user) {
  final wallet = ref.watch(walletBalancesProvider).valueOrNull;
  final stats =
      ref.watch(profileStatsProvider).valueOrNull ?? const ProfileStatsEntity();
  final level =
      ref.watch(userLevelProvider).valueOrNull ?? const UserLevelEntity();
  final access = ref.watch(fortuneAccessStateProvider).valueOrNull;
  final staff = ref.watch(staffAccessProvider);
  final approved = ref.watch(approvedPsychicProvider);

  var state = buildProfileWalletState(
    profileScreenStateFromUser(user).copyWith(stats: stats, level: level),
    wallet,
  );

  return state.copyWith(
    adCredits: access?.adCredits ?? wallet?.fortuneAdCredits ?? 0,
    isStaff: staff.canManagePayments,
    isAdmin: staff.canManagePayments,
    isApprovedTeller: approved.isApprovedTeller,
  );
}
