import '../../../core/util/json_util.dart';

/// `POST /api/user/watch-ad` ve `POST /api/ads/reward` ödül tutarı.
int parseWatchAdRewardAmount(dynamic body) {
  if (body is! Map) return 0;
  var map = asJsonMap(body);
  if (map['data'] is Map) map = asJsonMap(map['data']);
  final credited = asInt(
    pick(map, [
      'creditsEarned',
      'credit',
      'credits',
      'reward',
      'amount',
      'jeton',
      'cfc',
    ]),
  );
  if (credited > 0) return credited;
  return asInt(
    pick(map, ['newBalance', 'balance', 'jetonBalance', 'cfcBalance']),
  );
}
