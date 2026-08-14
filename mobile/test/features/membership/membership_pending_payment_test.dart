import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/wallet/domain/cfc_payment_request_entity.dart';

void main() {
  group('CfcPaymentRequestEntity membership filter', () {
    test('packageId membership_ ile eşleşir', () {
      const req = CfcPaymentRequestEntity(
        id: '1',
        amount: 1000,
        method: 'whatsapp',
        status: 'pending',
        packageId: 'membership_gold',
      );
      expect(req.isMembershipCheckout, isTrue);
      expect(req.isPending, isTrue);
    });

    test('notes üyelik içerir', () {
      const req = CfcPaymentRequestEntity(
        id: '2',
        amount: 500,
        method: 'cfc_balance',
        status: 'pending',
        notes: 'Üyelik · Gold · CFC',
      );
      expect(req.isMembershipCheckout, isTrue);
    });

    test('jeton talebi üyelik değil', () {
      const req = CfcPaymentRequestEntity(
        id: '3',
        amount: 2000,
        method: 'whatsapp',
        status: 'pending',
        requestType: 'jeton',
        packageId: 'p2000',
      );
      expect(req.isMembershipCheckout, isFalse);
      expect(req.isJeton, isTrue);
    });
  });
}
