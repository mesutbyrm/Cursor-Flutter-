import 'package:equatable/equatable.dart';

import '../../util/json_util.dart';

/// `POST /api/bana-ozel/open` HTTP 402 yanıtı.
class BanaOzelInsufficientPayment extends Equatable implements Exception {
  const BanaOzelInsufficientPayment({
    required this.message,
    required this.requiredAmount,
    required this.cfcBalance,
    required this.jetonBalance,
    this.canWatchAd = false,
    this.adRemaining = 0,
    this.adUnlimited = false,
  });

  factory BanaOzelInsufficientPayment.fromJson(Map<String, dynamic> json) {
    return BanaOzelInsufficientPayment(
      message: pick(json, ['error', 'message'])?.toString() ??
          'Yetersiz bakiye',
      requiredAmount: asInt(pick(json, ['required', 'cost'])),
      cfcBalance: asInt(pick(json, ['cfcBalance', 'current', 'credits'])),
      jetonBalance: asInt(pick(json, ['jetonBalance'])),
      canWatchAd: json['canWatchAd'] == true,
      adRemaining: asInt(pick(json, ['adRemaining'])),
      adUnlimited: json['adUnlimited'] == true,
    );
  }

  final String message;
  final int requiredAmount;
  final int cfcBalance;
  final int jetonBalance;
  final bool canWatchAd;
  final int adRemaining;
  final bool adUnlimited;

  bool get hasAnyBalance => cfcBalance > 0 || jetonBalance > 0;

  @override
  List<Object?> get props => [
        message,
        requiredAmount,
        cfcBalance,
        jetonBalance,
        canWatchAd,
        adRemaining,
        adUnlimited,
      ];
}

/// Ekonomi v2 spin/oyun yanıtında birim alanı.
enum EconomyCurrencyUnit {
  cfc,
  jeton,
  unknown;

  static EconomyCurrencyUnit parse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'cfc':
      case 'credits':
        return EconomyCurrencyUnit.cfc;
      case 'jeton':
        return EconomyCurrencyUnit.jeton;
      default:
        return EconomyCurrencyUnit.unknown;
    }
  }

  /// Legacy alan adları CFC taşıyabilir — ZIP uyarısı.
  static EconomyCurrencyUnit fromResponseFields({
    String? currency,
    String? paymentMethod,
  }) {
    final direct = parse(currency ?? paymentMethod);
    if (direct != EconomyCurrencyUnit.unknown) return direct;
    return EconomyCurrencyUnit.cfc;
  }
}
