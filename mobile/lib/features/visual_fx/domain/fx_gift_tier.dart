/// Hediye jeton değerine göre görsel yoğunluk kademesi.
enum FxGiftTier {
  small,
  medium,
  special,
  legendary;

  static const int defaultBigGiftThreshold = 1000;
  static const int defaultLegendaryThreshold = 10000;

  static FxGiftTier fromJeton(int jeton, {int? bigThreshold, int? legendaryThreshold}) {
    final big = bigThreshold ?? defaultBigGiftThreshold;
    final legendary = legendaryThreshold ?? defaultLegendaryThreshold;
    if (jeton >= legendary) return FxGiftTier.legendary;
    if (jeton >= big) return FxGiftTier.special;
    if (jeton >= 100) return FxGiftTier.medium;
    return FxGiftTier.small;
  }

  bool get isBigGift => index >= FxGiftTier.special.index;
}
