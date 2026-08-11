import 'package:equatable/equatable.dart';

import '../../../core/util/json_util.dart';
import '../../../core/auth/staff_roles.dart';

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
    this.favoriteTeam,
    this.teamRaw,
    this.fortuneAdCredits,
    this.canManagePayments,
    this.isAdminFlag,
    this.isStaffFlag,
    this.totalEarnedJeton,
    this.pendingEarningsTl,
    this.approvedEarningsTl,
    this.withdrawableTl,
    this.todayEarningsTl,
    this.monthEarningsTl,
    this.totalSentJeton,
    this.totalReceivedJeton,
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
    String? favoriteTeam,
    Map<String, dynamic>? teamRaw,
    int? fortuneAdCredits,
    bool? canManagePayments,
    bool? isAdminFlag,
    bool? isStaffFlag,
    int? totalEarnedJeton,
    double? pendingEarningsTl,
    double? approvedEarningsTl,
    double? withdrawableTl,
    double? todayEarningsTl,
    double? monthEarningsTl,
    int? totalSentJeton,
    int? totalReceivedJeton,
  }) {
    return WalletBalances(
      jeton: jeton ?? this.jeton,
      cfc: cfc ?? this.cfc,
      role: role ?? this.role,
      jetonTlRate: jetonTlRate ?? this.jetonTlRate,
      withdrawalLimit: withdrawalLimit ?? this.withdrawalLimit,
      membership: membership ?? this.membership,
      membershipExpiresAt: membershipExpiresAt ?? this.membershipExpiresAt,
      favoriteTeam: favoriteTeam ?? this.favoriteTeam,
      teamRaw: teamRaw ?? this.teamRaw,
      fortuneAdCredits: fortuneAdCredits ?? this.fortuneAdCredits,
      canManagePayments: canManagePayments ?? this.canManagePayments,
      isAdminFlag: isAdminFlag ?? this.isAdminFlag,
      isStaffFlag: isStaffFlag ?? this.isStaffFlag,
      totalEarnedJeton: totalEarnedJeton ?? this.totalEarnedJeton,
      pendingEarningsTl: pendingEarningsTl ?? this.pendingEarningsTl,
      approvedEarningsTl: approvedEarningsTl ?? this.approvedEarningsTl,
      withdrawableTl: withdrawableTl ?? this.withdrawableTl,
      todayEarningsTl: todayEarningsTl ?? this.todayEarningsTl,
      monthEarningsTl: monthEarningsTl ?? this.monthEarningsTl,
      totalSentJeton: totalSentJeton ?? this.totalSentJeton,
      totalReceivedJeton: totalReceivedJeton ?? this.totalReceivedJeton,
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
    Map<String, dynamic>? teamRaw;
    final teamNode = json['team'];
    if (teamNode is Map) teamRaw = asJsonMap(teamNode);
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
      favoriteTeam:
          pick(json, ['favoriteTeam', 'favorite_team', 'teamName'])?.toString(),
      teamRaw: teamRaw,
      fortuneAdCredits: fortuneAdCredits,
      canManagePayments: pick(json, ['canManagePayments']) == true,
      isAdminFlag: pick(json, ['isAdmin']) == true,
      isStaffFlag: pick(json, ['isStaff']) == true,
      totalEarnedJeton: asInt(pick(json, [
        'totalEarnedJeton',
        'totalEarned',
        'earningsJeton',
        'lifetimeEarnings',
      ])),
      pendingEarningsTl: _asDouble(pick(json, [
        'pendingEarnings',
        'pendingBalance',
        'pendingEarningsTl',
      ])),
      approvedEarningsTl: _asDouble(pick(json, [
        'approvedEarnings',
        'approvedBalance',
        'approvedEarningsTl',
      ])),
      withdrawableTl: _asDouble(pick(json, [
        'withdrawable',
        'withdrawableBalance',
        'withdrawableTl',
      ])),
      todayEarningsTl: _asDouble(pick(json, [
        'todayEarnings',
        'todayEarningsTl',
        'dailyEarnings',
      ])),
      monthEarningsTl: _asDouble(pick(json, [
        'monthEarnings',
        'monthEarningsTl',
        'monthlyEarnings',
      ])),
      totalSentJeton: asInt(pick(json, [
        'totalSentJeton',
        'sentJeton',
        'giftsSentTotal',
      ])),
      totalReceivedJeton: asInt(pick(json, [
        'totalReceivedJeton',
        'receivedJeton',
        'giftsReceivedTotal',
      ])),
    );
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  final int jeton;
  final int cfc;
  final String? role;
  final double? jetonTlRate;
  final int withdrawalLimit;
  final String? membership;
  final String? membershipExpiresAt;
  final String? favoriteTeam;
  final Map<String, dynamic>? teamRaw;
  final int? fortuneAdCredits;
  final bool? canManagePayments;
  final bool? isAdminFlag;
  final bool? isStaffFlag;
  final int? totalEarnedJeton;
  final double? pendingEarningsTl;
  final double? approvedEarningsTl;
  final double? withdrawableTl;
  final double? todayEarningsTl;
  final double? monthEarningsTl;
  final int? totalSentJeton;
  final int? totalReceivedJeton;

  double? jetonToTl(int jetonAmount) {
    final rate = jetonTlRate;
    if (rate == null || rate <= 0) return null;
    return jetonAmount * rate;
  }

  String formatTl(double? value) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(2)} TL';
  }

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
    if (isStaffFlag == true) return true;
    final r = role?.toLowerCase().trim() ?? '';
    return const {
      'admin',
      'yonetici',
      'moderator',
      'destek',
      'yardim',
      'super_admin',
      'superadmin',
      'founder',
    }.contains(r);
  }

  bool get isAdmin =>
      isAdminFlag == true ||
      canManagePayments == true ||
      StaffRoles.isAdminOrManager(role: role);

  @override
  List<Object?> get props => [
        jeton,
        cfc,
        role,
        jetonTlRate,
        withdrawalLimit,
        membership,
        membershipExpiresAt,
        favoriteTeam,
        teamRaw,
        fortuneAdCredits,
        canManagePayments,
        isAdminFlag,
        isStaffFlag,
        totalEarnedJeton,
        pendingEarningsTl,
        approvedEarningsTl,
        withdrawableTl,
        todayEarningsTl,
        monthEarningsTl,
        totalSentJeton,
        totalReceivedJeton,
      ];
}
