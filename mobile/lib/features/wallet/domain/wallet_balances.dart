import 'package:equatable/equatable.dart';

import '../../../core/util/json_util.dart';

/// Jeton + CFC — `GET /api/user/credits` (canlifal.com).
class WalletBalances extends Equatable {
  const WalletBalances({
    this.jeton = 0,
    this.cfc = 0,
    this.role,
    this.jetonTlRate,
    this.withdrawalLimit = 0,
    this.membership,
    this.membershipExpiresAt,
  });

  factory WalletBalances.fromJson(Map<String, dynamic> json) {
    final jeton = asInt(
      pick(json, [
        'jetonBalance',
        'jeton',
        'credits',
        'coins',
        'coinBalance',
        'balance',
      ]),
    );
    final cfc = asInt(
      pick(json, ['cfcBalance', 'cfc', 'cfc_balance', 'diamonds']),
    );
    return WalletBalances(
      jeton: jeton,
      cfc: cfc,
      role: pick(json, ['role', 'tier'])?.toString(),
      jetonTlRate: pick(json, ['jetonTlRate', 'jeton_tl_rate']) != null
          ? (pick(json, ['jetonTlRate', 'jeton_tl_rate']) as num).toDouble()
          : null,
      withdrawalLimit: asInt(pick(json, ['withdrawalLimit', 'withdrawal_limit'])),
      membership: pick(json, ['membership'])?.toString(),
      membershipExpiresAt:
          pick(json, ['membershipExpiresAt', 'membership_expires_at'])?.toString(),
    );
  }

  final int jeton;
  final int cfc;
  final String? role;
  final double? jetonTlRate;
  final int withdrawalLimit;
  final String? membership;
  final String? membershipExpiresAt;

  bool get isStaff {
    final r = role?.toLowerCase().trim() ?? '';
    return const {
      'admin',
      'yonetici',
      'moderator',
      'destek',
      'yardim',
    }.contains(r);
  }

  @override
  List<Object?> get props =>
      [jeton, cfc, role, jetonTlRate, withdrawalLimit, membership];
}
