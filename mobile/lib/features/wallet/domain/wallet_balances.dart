import 'package:equatable/equatable.dart';

import '../../../core/util/json_util.dart';

/// Jeton + CFC çift bakiye (canlifal.com `/api/user/credits`).
class WalletBalances extends Equatable {
  const WalletBalances({
    this.jeton = 0,
    this.cfc = 0,
    this.role,
  });

  factory WalletBalances.fromJson(Map<String, dynamic> json) {
    final jeton = asInt(
      pick(json, [
        'jeton',
        'credits',
        'coins',
        'coinBalance',
        'balance',
        'amount',
      ]),
    );
    final cfc = asInt(
      pick(json, ['cfc', 'cfcBalance', 'cfc_balance', 'diamonds']),
    );
    return WalletBalances(
      jeton: jeton,
      cfc: cfc,
      role: pick(json, ['role', 'tier'])?.toString(),
    );
  }

  final int jeton;
  final int cfc;
  final String? role;

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
  List<Object?> get props => [jeton, cfc, role];
}
