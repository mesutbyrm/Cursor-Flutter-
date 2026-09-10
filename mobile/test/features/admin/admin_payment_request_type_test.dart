import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/admin/domain/admin_payment_review.dart';

void main() {
  group('resolvePaymentRequestType', () {
    test('jeton from requestType and coins without amount', () {
      expect(
        resolvePaymentRequestType({
          'requestType': 'jeton',
          'coins': 500,
          'priceTry': 250,
        }),
        'jeton',
      );
    });

    test('cfc from amount-only CFC checkout', () {
      expect(
        resolvePaymentRequestType({
          'requestType': 'cfc',
          'amount': 1200,
          'priceTry': 99,
        }),
        'cfc',
      );
    });

    test('jeton from mobile source when type missing', () {
      expect(
        resolvePaymentRequestType({
          'source': 'mobile_jeton_checkout',
          'coins': 100,
        }),
        'jeton',
      );
    });

    test('does not treat priceTry alone as jeton', () {
      expect(
        resolvePaymentRequestType({
          'amount': 500,
          'priceTry': 50,
        }),
        'cfc',
      );
    });
  });
}
