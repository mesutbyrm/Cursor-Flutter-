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

  static const jetonUsageItems = [
    'Canlı yayınlar',
    'Sesli sohbet odaları',
    'Fal & Tarot',
    'Hediye yolla — gönderilen hediyeler paraya çevrilebilir',
    'Hediye yolla — başkasına jeton hediye gönderebilirsiniz',
    'Canlı falcılarda kullanılabilir',
  ];

  static double tlForCfc(int cfcAmount) => cfcAmount * cfcTlPerCoin;
}
