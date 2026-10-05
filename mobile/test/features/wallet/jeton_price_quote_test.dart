import 'package:canlifal_social/features/wallet/domain/jeton_price_quote.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sunucu quote.finalAmount okunur', () {
    final q = JetonPriceQuote.fromJson({
      'unitPrice': 0.5,
      'discountEnabled': false,
      'quote': {
        'jetonAmount': 10000,
        'unitPrice': 0.5,
        'baseAmount': 5000,
        'discountAmount': 0,
        'finalAmount': 5000,
      },
    });
    expect(q.jetonAmount, 10000);
    expect(q.finalAmount, 5000);
    expect(q.unitPrice, 0.5);
  });
}
