import 'json_util.dart';

/// Fal fiyat parse — yalnızca pozitif değerler (0/null gizlenir).
int? parseFortuneJetonPrice(Map<String, dynamic> json) {
  final value = pick(json, [
    'jetonCost',
    'cost',
    'price',
    'jetonPrice',
    'priceInTokens',
    'credits',
  ]);
  final parsed = asInt(value);
  return parsed > 0 ? parsed : null;
}
