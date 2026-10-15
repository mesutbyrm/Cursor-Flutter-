/// `GET /api/withdrawals/quote?amount=<jeton>` — kesinti dahil tahmini net tutar.
class WithdrawalQuote {
  const WithdrawalQuote({
    required this.jetonAmount,
    required this.jetonBalance,
    required this.rate,
    required this.minWithdrawal,
    required this.grossTL,
    required this.taxPercent,
    required this.taxAmount,
    required this.netAmountTL,
    required this.grossLabel,
    required this.taxLabel,
    required this.netLabel,
  });

  final int jetonAmount;
  final int jetonBalance;
  final double rate;
  final int minWithdrawal;
  final double grossTL;
  final double taxPercent;
  final double taxAmount;
  final double netAmountTL;
  final String grossLabel;
  final String taxLabel;
  final String netLabel;

  static double _n(Object? v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  factory WithdrawalQuote.fromJson(Map<String, dynamic> json) {
    final labels = json['labels'] is Map
        ? Map<String, dynamic>.from(json['labels'] as Map)
        : const <String, dynamic>{};
    final tax = _n(json['taxPercent']);
    return WithdrawalQuote(
      jetonAmount: _n(json['jetonAmount']).round(),
      jetonBalance: _n(json['jetonBalance']).round(),
      rate: _n(json['rate']),
      minWithdrawal: _n(json['minWithdrawal']).round(),
      grossTL: _n(json['grossTL']),
      taxPercent: tax,
      taxAmount: _n(json['taxAmount']),
      netAmountTL: _n(json['netAmountTL']),
      grossLabel: '${labels['gross'] ?? 'Toplam kazandığınız'}',
      taxLabel: '${labels['tax'] ?? (tax > 0 ? 'Kesinti (%$tax)' : 'Kesinti yok')}',
      netLabel: '${labels['net'] ?? 'Elinize geçecek tahmini tutar'}',
    );
  }
}
