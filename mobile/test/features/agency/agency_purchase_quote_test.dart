import 'package:canlifal_social/features/agency/data/datasources/agency_wallet_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AgencyPurchaseQuote jeton modu (indirim)', () {
    final q = AgencyPurchaseQuote.fromJson({
      'mode': 'jeton',
      'jetonAmount': 100000,
      'bonusJeton': 0,
      'totalJeton': 100000,
      'normalPriceTl': 200000,
      'finalPriceTl': 180000,
      'discountPercent': 10,
      'bonusPercent': 5,
      'savedTl': 20000,
    });
    expect(q.mode, AgencyPurchaseQuoteMode.jeton);
    expect(q.loadedJeton, 100000);
    expect(q.bonusJeton, 0);
  });

  test('AgencyPurchaseQuote tl modu (bonus)', () {
    final q = AgencyPurchaseQuote.fromJson({
      'mode': 'tl',
      'jetonAmount': 50000,
      'bonusJeton': 5000,
      'totalJeton': 55000,
      'finalPriceTl': 90000,
      'bonusPercent': 10,
    });
    expect(q.mode, AgencyPurchaseQuoteMode.tl);
    expect(q.loadedJeton, 55000);
    expect(q.bonusJeton, 5000);
  });
}
