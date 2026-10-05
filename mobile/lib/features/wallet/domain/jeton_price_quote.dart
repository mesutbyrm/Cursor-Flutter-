/// `GET /api/public/jeton-price?jeton=<adet>` yanıtı — tutarı yalnızca sunucu belirler.
class JetonPriceQuote {
  const JetonPriceQuote({
    required this.jetonAmount,
    required this.unitPrice,
    required this.baseAmount,
    required this.discountAmount,
    required this.finalAmount,
  });

  final int jetonAmount;
  final double unitPrice;
  final double baseAmount;
  final double discountAmount;

  /// Ödeme bildiriminde `amount` olarak gönderilecek tek geçerli tutar.
  final double finalAmount;

  static double _num(Object? v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  factory JetonPriceQuote.fromJson(Map<String, dynamic> json) {
    final q = json['quote'] is Map
        ? Map<String, dynamic>.from(json['quote'] as Map)
        : json;
    return JetonPriceQuote(
      jetonAmount: _num(q['jetonAmount']).round(),
      unitPrice: _num(q['unitPrice'] ?? json['unitPrice']),
      baseAmount: _num(q['baseAmount']),
      discountAmount: _num(q['discountAmount']),
      finalAmount: _num(q['finalAmount']),
    );
  }
}
