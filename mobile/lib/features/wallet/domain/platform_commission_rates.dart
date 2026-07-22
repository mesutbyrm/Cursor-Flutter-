import 'package:equatable/equatable.dart';

import '../../../core/util/json_util.dart';

/// Platform komisyon oranları — `GET /api/platform/commission-rate` (salt okunur).
class PlatformCommissionRates extends Equatable {
  const PlatformCommissionRates({
    this.sitePercent,
    this.ownerPercent,
    this.receiverPercent,
    this.taxPercent,
    this.extraDeductionPercent,
    this.jetonTlRate,
    this.minWithdrawalTl,
    this.maxWithdrawalTl,
    this.dailyWithdrawalLimitTl,
  });

  factory PlatformCommissionRates.fromJson(Map<String, dynamic> json) {
    double? pct(dynamic v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
    return PlatformCommissionRates(
      sitePercent: pct(pick(json, [
        'sitePercent',
        'siteCommission',
        'site',
        'platformPercent',
      ])),
      ownerPercent: pct(pick(json, [
        'ownerPercent',
        'roomOwnerPercent',
        'owner',
        'broadcasterPercent',
      ])),
      receiverPercent: pct(pick(json, [
        'receiverPercent',
        'giftReceiverPercent',
        'receiver',
      ])),
      taxPercent: pct(pick(json, ['taxPercent', 'tax', 'vergiPercent'])),
      extraDeductionPercent: pct(pick(json, [
        'extraDeductionPercent',
        'extraDeduction',
        'ekKesintiPercent',
      ])),
      jetonTlRate: pct(pick(json, ['jetonTlRate', 'jeton_tl_rate', 'tlRate'])),
      minWithdrawalTl: pct(pick(json, [
        'minWithdrawal',
        'minWithdrawalTl',
        'minimumWithdrawal',
      ])),
      maxWithdrawalTl: pct(pick(json, [
        'maxWithdrawal',
        'maxWithdrawalTl',
        'maximumWithdrawal',
      ])),
      dailyWithdrawalLimitTl: pct(pick(json, [
        'dailyLimit',
        'dailyWithdrawalLimit',
      ])),
    );
  }

  final double? sitePercent;
  final double? ownerPercent;
  final double? receiverPercent;
  final double? taxPercent;
  final double? extraDeductionPercent;
  final double? jetonTlRate;
  final double? minWithdrawalTl;
  final double? maxWithdrawalTl;
  final double? dailyWithdrawalLimitTl;

  @override
  List<Object?> get props => [
        sitePercent,
        ownerPercent,
        receiverPercent,
        taxPercent,
        extraDeductionPercent,
        jetonTlRate,
        minWithdrawalTl,
        maxWithdrawalTl,
        dailyWithdrawalLimitTl,
      ];
}
