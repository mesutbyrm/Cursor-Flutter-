import 'package:equatable/equatable.dart';

import '../../util/json_util.dart';
import 'currency_brand.dart';

/// `GET /api/currency-branding` yanıtı.
class CurrencyBrandingSnapshot extends Equatable {
  const CurrencyBrandingSnapshot({
    required this.jeton,
    required this.cfc,
    this.convertibleKeys = const ['jeton'],
    this.rewardCurrency = 'cfc',
  });

  factory CurrencyBrandingSnapshot.fromJson(Map<String, dynamic> json) {
    final jetonRaw = pick(json, ['jeton']);
    final cfcRaw = pick(json, ['cfc']);
    final rules = pick(json, ['rules']);
    final rulesMap = rules is Map ? asJsonMap(rules) : <String, dynamic>{};
    final convertible = rulesMap['convertible'];
    return CurrencyBrandingSnapshot(
      jeton: jetonRaw is Map
          ? CurrencyBrand.fromJson(asJsonMap(jetonRaw))
          : CurrencyBrand.jetonFallback,
      cfc: cfcRaw is Map
          ? CurrencyBrand.fromJson(asJsonMap(cfcRaw))
          : CurrencyBrand.cfcFallback,
      convertibleKeys: convertible is List
          ? convertible.map((e) => e.toString()).toList()
          : const ['jeton'],
      rewardCurrency:
          pick(rulesMap, ['rewardCurrency'])?.toString() ?? 'cfc',
    );
  }

  static const defaults = CurrencyBrandingSnapshot(
    jeton: CurrencyBrand.jetonFallback,
    cfc: CurrencyBrand.cfcFallback,
  );

  final CurrencyBrand jeton;
  final CurrencyBrand cfc;
  final List<String> convertibleKeys;
  final String rewardCurrency;

  CurrencyBrand brandForKey(String key) {
    switch (key.toLowerCase()) {
      case 'jeton':
        return jeton;
      case 'cfc':
      case 'credits':
        return cfc;
      default:
        return cfc;
    }
  }

  @override
  List<Object?> get props =>
      [jeton, cfc, convertibleKeys, rewardCurrency];
}
