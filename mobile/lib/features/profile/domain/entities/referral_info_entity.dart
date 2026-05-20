import 'package:equatable/equatable.dart';

/// canlifal.com `/api/referral` yanıtından türetilen davet bilgisi.
class ReferralInfoEntity extends Equatable {
  const ReferralInfoEntity({
    this.code,
    required this.shareUrl,
    this.headline,
    this.invitedCount,
    this.rewardHint,
  });

  final String? code;
  final String shareUrl;
  final String? headline;
  final int? invitedCount;
  final String? rewardHint;

  @override
  List<Object?> get props =>
      [code, shareUrl, headline, invitedCount, rewardHint];
}
