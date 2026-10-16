import 'package:canlifal_social/features/admin/presentation/providers/admin_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('jeton ödeme bildirimi satırı: adet requestedAmount, tutar TL', () {
    final row = <String, dynamic>{
      'id': 'n1',
      'productType': 'jeton',
      'paymentMethod': 'papara',
      'amount': 1000,
      'requestedAmount': 2000,
    };
    final line = paymentRequestDetailLine(row);
    expect(line, contains('Jeton: 2000'));
    expect(line, contains('₺1000'));
  });

  test('CFC talebi satırı değişmedi', () {
    final row = <String, dynamic>{
      'id': 'c1',
      'requestType': 'cfc',
      'method': 'papara',
      'amount': 500,
    };
    expect(paymentRequestSummary(row), startsWith('500 CFC'));
  });
}
