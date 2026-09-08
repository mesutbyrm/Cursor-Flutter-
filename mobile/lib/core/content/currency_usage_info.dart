/// CFC ve Jeton kullanım alanları — uygulama genelinde aynı metin.
abstract final class CurrencyUsageInfo {
  static const cfcTitle = 'CFC (CanlıFal Coin)';
  static const jetonTitle = 'Jeton';

  static const cfcNotConvertible =
      'CFC paraya dönüşmez. Yalnızca aşağıdaki alanlarda harcanır.';

  static const cfcPriceHint = '100 CFC = 25 TL';

  /// 1 CFC kaç TL (100 CFC = 25 TL).
  static const double cfcTlPerCoin = 0.25;

  static const cfcUsageItems = [
    'Oyunlarda',
    'Fal & Tarot',
  ];

  static String cfcTitleFor(String cfcLabel) => '$cfcLabel (CanlıFal Coin)';

  static String cfcPriceHintFor(String cfcLabel) => '100 $cfcLabel = 25 TL';

  static String cfcNotConvertibleFor(String cfcLabel) =>
      '$cfcLabel paraya dönüşmez. Yalnızca aşağıdaki alanlarda harcanır.';

  static List<String> jetonUsageItemsFor(String jetonLabel) => [
    'Canlı yayınlar',
    'Sesli sohbet odaları',
    'Fal & Tarot',
    'Hediye yolla — gönderilen hediyeler paraya çevrilebilir',
    'Hediye yolla — başkasına $jetonLabel hediye gönderebilirsiniz',
    'Canlı falcılarda kullanılabilir',
  ];

  static double tlForCfc(int cfcAmount) => cfcAmount * cfcTlPerCoin;

  /// TL tutarından gerekli CFC (yukarı yuvarlanır).
  static int cfcForTl(num tl) {
    if (tl <= 0) return 0;
    return (tl / cfcTlPerCoin).ceil();
  }
}
