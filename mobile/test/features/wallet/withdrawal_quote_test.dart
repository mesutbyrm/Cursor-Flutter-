import 'package:canlifal_social/features/wallet/domain/withdrawal_quote.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kesinti ve net tutar sunucudan okunur', () {
    final q = WithdrawalQuote.fromJson({
      'jetonAmount': 10000,
      'jetonBalance': 12000,
      'rate': 0.5,
      'minWithdrawal': 100,
      'grossTL': 5000,
      'taxPercent': 20,
      'taxAmount': 1000,
      'netAmountTL': 4000,
      'labels': {
        'gross': 'Toplam kazandığınız',
        'tax': 'Kesinti (%20)',
        'net': 'Elinize geçecek tahmini tutar',
      },
    });
    expect(q.grossTL, 5000);
    expect(q.taxAmount, 1000);
    expect(q.netAmountTL, 4000);
    expect(q.taxLabel, 'Kesinti (%20)');
    expect(q.minWithdrawal, 100);
  });
}
