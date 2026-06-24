import '../../../../core/util/json_util.dart';

/// Admin + varsayılan AI fal erişim ayarları.
class FortuneAccessConfig {
  const FortuneAccessConfig({
    this.jetonCost = 10,
    this.adCreditsPerAd = 1,
    this.dailyAdLimit = 20,
    this.adsEnabled = true,
    this.adRequired = false,
    this.premiumUnlimited = true,
  });

  static const defaults = FortuneAccessConfig();

  final int jetonCost;
  final int adCreditsPerAd;
  final int dailyAdLimit;
  final bool adsEnabled;
  final bool adRequired;
  final bool premiumUnlimited;

  factory FortuneAccessConfig.fromJson(Map<String, dynamic> json) {
    final jetonRaw = pick(json, ['jetonCost', 'fortuneJetonCost', 'cost']);
    final creditsRaw =
        pick(json, ['adCreditsPerAd', 'creditsPerAd', 'rewardPerAd']);
    final limitRaw =
        pick(json, ['dailyAdLimit', 'dailyAdWatchLimit', 'maxAdsPerDay']);
    return FortuneAccessConfig(
      jetonCost: jetonRaw != null ? asInt(jetonRaw) : 10,
      adCreditsPerAd: creditsRaw != null ? asInt(creditsRaw) : 1,
      dailyAdLimit: limitRaw != null ? asInt(limitRaw) : 20,
      adsEnabled: pick(json, ['adsEnabled', 'adEnabled', 'rewardedAdsEnabled']) != false,
      adRequired: pick(json, ['adRequired', 'requireAd', 'fortuneAdRequired']) == true,
      premiumUnlimited: pick(json, ['premiumUnlimited', 'unlimitedPremiumFortune']) != false,
    );
  }

  FortuneAccessConfig copyWith({
    int? jetonCost,
    int? adCreditsPerAd,
    int? dailyAdLimit,
    bool? adsEnabled,
    bool? adRequired,
    bool? premiumUnlimited,
  }) {
    return FortuneAccessConfig(
      jetonCost: jetonCost ?? this.jetonCost,
      adCreditsPerAd: adCreditsPerAd ?? this.adCreditsPerAd,
      dailyAdLimit: dailyAdLimit ?? this.dailyAdLimit,
      adsEnabled: adsEnabled ?? this.adsEnabled,
      adRequired: adRequired ?? this.adRequired,
      premiumUnlimited: premiumUnlimited ?? this.premiumUnlimited,
    );
  }
}

/// Fal açma yöntemi.
enum FortuneAccessMethod {
  premium,
  adCredit,
  jeton,
}

class FortuneAccessGrant {
  const FortuneAccessGrant({required this.method, this.jetonCost = 10});

  final FortuneAccessMethod method;
  final int jetonCost;
}
