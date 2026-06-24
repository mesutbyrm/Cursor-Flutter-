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
    this.fortuneAdCredits,
  });

  static const empty = WalletBalances();

  WalletBalances copyWith({
    int? jeton,
    int? cfc,
    String? role,
    double? jetonTlRate,
    int? withdrawalLimit,
    String? membership,
    String? membershipExpiresAt,
    int? fortuneAdCredits,
  }) {
    return WalletBalances(
      jeton: jeton ?? this.jeton,
      cfc: cfc ?? this.cfc,
      role: role ?? this.role,
      jetonTlRate: jetonTlRate ?? this.jetonTlRate,
      withdrawalLimit: withdrawalLimit ?? this.withdrawalLimit,
      membership: membership ?? this.membership,
      membershipExpiresAt: membershipExpiresAt ?? this.membershipExpiresAt,
      fortuneAdCredits: fortuneAdCredits ?? this.fortuneAdCredits,
    );
  }

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
    final rawCredits = pick(json, [
      'fortuneAdCredits',
      'fortune_ad_credits',
      'adFortuneCredits',
      'freeFortuneCredits',
    ]);
    final fortuneAdCredits =
        rawCredits != null ? asInt(rawCredits) : null;
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
      fortuneAdCredits: fortuneAdCredits,
    );
  }

  final int jeton;
  final int cfc;
  final String? role;
  final double? jetonTlRate;
  final int withdrawalLimit;
  final String? membership;
  final String? membershipExpiresAt;
  final int? fortuneAdCredits;

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
  List<Object?> get props => [
        jeton,
        cfc,
        role,
        jetonTlRate,
        withdrawalLimit,
        membership,
        fortuneAdCredits,
      ];
}
