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

  /// Kalan üyelik günü (`membershipExpiresAt` ISO).
  int? get membershipDaysRemaining {
    final raw = membershipExpiresAt;
    if (raw == null || raw.isEmpty) return null;
    final exp = DateTime.tryParse(raw);
    if (exp == null) return null;
    final diff = exp.difference(DateTime.now());
    if (diff.isNegative) return 0;
    return diff.inDays + (diff.inHours % 24 > 0 ? 1 : 0);
  }

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
