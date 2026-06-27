import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';

/// Profil ekranı — birleşik görünüm modeli (mevcut API'lerden).
class ProfileScreenState extends Equatable {
  const ProfileScreenState({
    required this.user,
    this.wallet,
    this.stats = const ProfileStatsEntity(),
    this.level = const UserLevelEntity(),
    this.jeton = 0,
    this.cfc = 0,
    this.adCredits = 0,
    this.membership,
    this.membershipDays,
    this.isVip = false,
    this.isStaff = false,
    this.isAdmin = false,
    this.isApprovedTeller = false,
  });

  final UserEntity user;
  final WalletBalances? wallet;
  final ProfileStatsEntity stats;
  final UserLevelEntity level;
  final int jeton;
  final int cfc;
  final int adCredits;
  final String? membership;
  final int? membershipDays;
  final bool isVip;
  final bool isStaff;
  final bool isAdmin;
  final bool isApprovedTeller;

  int get followers => stats.followers > 0 ? stats.followers : user.followersCount;
  int get following => stats.following > 0 ? stats.following : user.followingCount;
  int get likes => stats.likes;
  int get liveStreams => stats.liveStreams;
  int get totalEarnings => stats.earningsJeton;
  int get profileViews => stats.profileViews;

  ProfileScreenState copyWith({
    UserEntity? user,
    WalletBalances? wallet,
    ProfileStatsEntity? stats,
    UserLevelEntity? level,
    int? jeton,
    int? cfc,
    int? adCredits,
    String? membership,
    int? membershipDays,
    bool? isVip,
    bool? isStaff,
    bool? isAdmin,
    bool? isApprovedTeller,
  }) {
    return ProfileScreenState(
      user: user ?? this.user,
      wallet: wallet ?? this.wallet,
      stats: stats ?? this.stats,
      level: level ?? this.level,
      jeton: jeton ?? this.jeton,
      cfc: cfc ?? this.cfc,
      adCredits: adCredits ?? this.adCredits,
      membership: membership ?? this.membership,
      membershipDays: membershipDays ?? this.membershipDays,
      isVip: isVip ?? this.isVip,
      isStaff: isStaff ?? this.isStaff,
      isAdmin: isAdmin ?? this.isAdmin,
      isApprovedTeller: isApprovedTeller ?? this.isApprovedTeller,
    );
  }

  @override
  List<Object?> get props => [user.id, jeton, cfc, stats, level.level];
}
