import '../domain/economy_payment_models.dart';
import '../domain/topup_bonus_tier.dart';

/// Oyun / şanslı hediye / günlük giriş yanıtlarında birim yorumlama.
abstract final class EconomyResponseAdapter {
  /// Legacy alan adları CFC taşıyabilir — `currency` alanı önceliklidir.
  static EconomyCurrencyUnit resolveSpinCurrency(Map<String, dynamic> json) {
    return EconomyCurrencyUnit.fromResponseFields(
      currency: json['currency']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
    );
  }

  static int resolveSpinBalanceAfter(Map<String, dynamic> json) {
    final currency = resolveSpinCurrency(json);
    if (currency == EconomyCurrencyUnit.jeton) {
      return _asInt(json['newJetonBalance'] ?? json['jetonBalance'] ?? json['newBalance']);
    }
    return _asInt(
      json['newCfcBalance'] ??
          json['cfcBalance'] ??
          json['newBalance'] ??
          json['credits'],
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }

  static List<TopupBonusTier> informationalBonusTiers() =>
      TopupBonusTier.defaultTiers;
}
