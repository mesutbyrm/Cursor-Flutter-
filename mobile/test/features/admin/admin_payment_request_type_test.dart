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

    test('amount+priceTry without CFC markers is jeton checkout', () {
      expect(
        resolvePaymentRequestType({
          'amount': 500,
          'priceTry': 50,
          'packageId': 'p500',
        }),
        'jeton',
      );
    });

    test('amount+priceTry with cfc source stays cfc', () {
      expect(
        resolvePaymentRequestType({
          'amount': 500,
          'priceTry': 50,
          'source': 'mobile_cfc_checkout',
        }),
        'cfc',
      );
    });

    test('notification type jeton_payment_request', () {
      expect(
        resolvePaymentRequestType({
          'type': 'jeton_payment_request',
          'amount': 500,
        }),
        'jeton',
      );
    });

    test('merge preserves requestType when second row is sparse', () {
      final merged = mergeAdminPaymentRequestRow(
        {'id': 'r1', 'amount': 500, 'status': 'pending'},
        {
          'id': 'r1',
          'requestType': 'jeton',
          'coins': 500,
          'packageId': 'p500',
        },
      );
      expect(merged['requestType'], 'jeton');
      expect(merged['coins'], 500);
      expect(resolvePaymentRequestType(merged), 'jeton');
    });

    test('review type prefers server requestType over UI guess', () {
      expect(
        resolvePaymentRequestTypeForReview(
          uiRequestType: 'cfc',
          requestRow: {'requestType': 'jeton', 'coins': 100},
        ),
        'jeton',
      );
    });
  });
}
