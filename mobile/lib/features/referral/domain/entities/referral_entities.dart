import 'package:equatable/equatable.dart';

/// Backend `/api/referral/stats` veya `/api/referral/me` yanıtı.
class ReferralStatsEntity extends Equatable {
  const ReferralStatsEntity({
    required this.referralCode,
    required this.shareUrl,
    this.headline,
    this.rewardHint,
    this.invitedCount = 0,
    this.activeReferralCount = 0,
    this.totalEarnings = 0,
    this.monthEarnings = 0,
    this.pendingEarnings = 0,
    this.availableEarnings = 0,
    this.reversedEarnings = 0,
    this.cappedEarnings = 0,
    this.lifetimeEarnings = 0,
    this.monthlyLimit = 0,
    this.lifetimeLimit = 0,
  });

  final String referralCode;
  final String shareUrl;
  final String? headline;
  final String? rewardHint;
  final int invitedCount;
  final int activeReferralCount;
  final int totalEarnings;
  final int monthEarnings;
  final int pendingEarnings;
  final int availableEarnings;
  final int reversedEarnings;
  final int cappedEarnings;
  final int lifetimeEarnings;
  final int monthlyLimit;
  final int lifetimeLimit;

  @override
  List<Object?> get props => [
        referralCode,
        shareUrl,
        headline,
        rewardHint,
        invitedCount,
        activeReferralCount,
        totalEarnings,
        monthEarnings,
        pendingEarnings,
        availableEarnings,
        reversedEarnings,
        cappedEarnings,
        lifetimeEarnings,
        monthlyLimit,
        lifetimeLimit,
      ];
}

class ReferralUserEntity extends Equatable {
  const ReferralUserEntity({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    required this.joinedAt,
    required this.status,
    this.eligibleJetonVolume = 0,
    this.referralEarnings = 0,
  });

  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String joinedAt;
  final String status;
  final int eligibleJetonVolume;
  final int referralEarnings;

  @override
  List<Object?> get props => [
        userId,
        username,
        displayName,
        avatarUrl,
        joinedAt,
        status,
        eligibleJetonVolume,
        referralEarnings,
      ];
}

class ReferralLedgerEntryEntity extends Equatable {
  const ReferralLedgerEntryEntity({
    required this.id,
    required this.referredUserId,
    required this.sourceType,
    required this.grossJeton,
    required this.beneficiaryShare,
    required this.referralCommission,
    required this.status,
    this.cappedAmount = 0,
    required this.createdAt,
  });

  final String id;
  final String referredUserId;
  final String sourceType;
  final int grossJeton;
  final int beneficiaryShare;
  final int referralCommission;
  final String status;
  final int cappedAmount;
  final String createdAt;

  @override
  List<Object?> get props => [
        id,
        referredUserId,
        sourceType,
        grossJeton,
        beneficiaryShare,
        referralCommission,
        status,
        cappedAmount,
        createdAt,
      ];
}
