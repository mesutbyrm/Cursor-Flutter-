import 'package:equatable/equatable.dart';

import '../../util/json_util.dart';
import 'currency_branding_snapshot.dart';

/// `GET /api/user/wallet` yanıtının mobil özeti.
class EconomyWalletSnapshot extends Equatable {
  const EconomyWalletSnapshot({
    this.cfc = 0,
    this.jeton = 0,
    this.legacyCfc = 0,
    this.branding = CurrencyBrandingSnapshot.defaults,
    this.referralCode,
    this.referralCreditsEarned = 0,
    this.tellerEarnings = 0,
    this.canWithdraw = false,
    this.minWithdrawal = 0,
    this.maxWithdrawal = 0,
    this.jetonTlRate = 0,
    this.estimatedTl = 0,
    this.transactions = const [],
    this.totalTransactions = 0,
  });

  factory EconomyWalletSnapshot.fromJson(Map<String, dynamic> json) {
    final balancesRaw = pick(json, ['balances']);
    final balances =
        balancesRaw is Map ? asJsonMap(balancesRaw) : <String, dynamic>{};
    final brandingRaw = pick(json, ['branding']);
    final earningsRaw = pick(json, ['earnings']);
    final earnings =
        earningsRaw is Map ? asJsonMap(earningsRaw) : <String, dynamic>{};
    final withdrawalRaw = pick(json, ['withdrawal']);
    final withdrawal = withdrawalRaw is Map
        ? asJsonMap(withdrawalRaw)
        : <String, dynamic>{};
    final txRaw = json['transactions'];
    final transactions = txRaw is List
        ? txRaw
            .whereType<Map>()
            .map((e) => EconomyWalletTransaction.fromJson(asJsonMap(e)))
            .toList()
        : const <EconomyWalletTransaction>[];

    return EconomyWalletSnapshot(
      cfc: asInt(pick(balances, ['cfc', 'credits'])),
      jeton: asInt(pick(balances, ['jeton', 'jetonBalance'])),
      legacyCfc: asInt(pick(balances, ['legacyCfc', 'cfcBalance'])),
      branding: brandingRaw is Map
          ? CurrencyBrandingSnapshot.fromJson(asJsonMap(brandingRaw))
          : CurrencyBrandingSnapshot.defaults,
      referralCode: pick(json, ['referralCode'])?.toString(),
      referralCreditsEarned:
          asInt(pick(earnings, ['referralCreditsEarned'])),
      tellerEarnings: asInt(pick(earnings, ['tellerEarnings'])),
      canWithdraw: withdrawal['canWithdraw'] == true,
      minWithdrawal: asInt(pick(withdrawal, ['minWithdrawal'])),
      maxWithdrawal: asInt(pick(withdrawal, ['maxWithdrawal'])),
      jetonTlRate: (pick(withdrawal, ['jetonTlRate']) as num?)?.toDouble() ?? 0,
      estimatedTl: (pick(withdrawal, ['estimatedTl']) as num?)?.toDouble() ?? 0,
      transactions: transactions,
      totalTransactions: asInt(pick(json, ['total'])),
    );
  }

  final int cfc;
  final int jeton;
  final int legacyCfc;
  final CurrencyBrandingSnapshot branding;
  final String? referralCode;
  final int referralCreditsEarned;
  final int tellerEarnings;
  final bool canWithdraw;
  final int minWithdrawal;
  final int maxWithdrawal;
  final double jetonTlRate;
  final double estimatedTl;
  final List<EconomyWalletTransaction> transactions;
  final int totalTransactions;

  @override
  List<Object?> get props => [
        cfc,
        jeton,
        legacyCfc,
        branding,
        referralCode,
        referralCreditsEarned,
        tellerEarnings,
        canWithdraw,
        minWithdrawal,
        maxWithdrawal,
        jetonTlRate,
        estimatedTl,
        transactions,
        totalTransactions,
      ];
}

class EconomyWalletTransaction extends Equatable {
  const EconomyWalletTransaction({
    required this.id,
    required this.currency,
    required this.amount,
    required this.type,
    this.description,
    this.balanceAfter = 0,
    this.createdAt,
  });

  factory EconomyWalletTransaction.fromJson(Map<String, dynamic> json) {
    return EconomyWalletTransaction(
      id: pick(json, ['id'])?.toString() ?? '',
      currency: pick(json, ['currency'])?.toString() ?? 'cfc',
      amount: asInt(pick(json, ['amount'])),
      type: pick(json, ['type'])?.toString() ?? '',
      description: pick(json, ['description'])?.toString(),
      balanceAfter: asInt(pick(json, ['balanceAfter', 'balance'])),
      createdAt: pick(json, ['createdAt'])?.toString(),
    );
  }

  final String id;
  final String currency;
  final int amount;
  final String type;
  final String? description;
  final int balanceAfter;
  final String? createdAt;

  @override
  List<Object?> get props =>
      [id, currency, amount, type, description, balanceAfter, createdAt];
}
