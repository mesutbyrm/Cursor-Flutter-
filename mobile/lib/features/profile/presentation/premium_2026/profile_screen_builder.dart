import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../fortune/presentation/providers/fortune_access_providers.dart';
import '../../../live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../providers/profile_providers.dart';
import 'profile_screen_state.dart';

/// Mevcut provider'lardan birleşik profil durumu.
ProfileScreenState buildProfileScreenState(WidgetRef ref, UserEntity user) {
  final wallet = ref.watch(walletBalancesProvider).valueOrNull;
  final stats =
      ref.watch(profileStatsProvider).valueOrNull ?? const ProfileStatsEntity();
  final level =
      ref.watch(userLevelProvider).valueOrNull ?? const UserLevelEntity();
  final access = ref.watch(fortuneAccessStateProvider).valueOrNull;
  final staff = ref.watch(staffAccessProvider);
  final approved = ref.watch(approvedPsychicProvider);

  final membership = wallet?.membership?.trim();
  final hasMembership = membership != null && membership.isNotEmpty;

  return ProfileScreenState(
    user: user,
    wallet: wallet,
    stats: stats,
    level: level,
    jeton: wallet?.jeton ?? user.coinBalance,
    cfc: wallet?.cfc ?? 0,
    adCredits: access?.adCredits ?? wallet?.fortuneAdCredits ?? 0,
    membership: hasMembership ? membership : null,
    membershipDays: wallet?.membershipDaysRemaining,
    isVip: hasMembership,
    isStaff: staff.canManagePayments,
    isAdmin: staff.canManagePayments,
    isApprovedTeller: approved.isApprovedTeller,
  );
}
