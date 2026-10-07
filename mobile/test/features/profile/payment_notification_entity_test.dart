import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/profile/domain/entities/payment_notification_entity.dart';

void main() {
  test('parses decorated GET /api/payments/notify array', () {
    final items = PaymentNotificationEntity.listFromResponse([
      {
        'id': 'p1',
        'status': 'rejected',
        'statusLabel': 'Reddedildi',
        'productLabel': 'Jeton',
        'amount': 150.5,
        'paymentMethodLabel': 'Havale/EFT',
        'adminMessage': 'Dekont okunamadı',
        'canDispute': true,
        'disputeTicketId': null,
        'createdAt': '2026-10-07T09:00:00.000Z',
      },
      {
        'id': 'p2',
        'status': 'corrected',
        'amount': '99',
        'canDispute': false,
        'disputeTicketId': 't9',
        'disputeStatus': 'open',
      },
    ]);
    expect(items, hasLength(2));
    expect(items[0].canDispute, isTrue);
    expect(items[0].hasDispute, isFalse);
    expect(items[0].amount, 150.5);
    expect(items[0].adminMessage, 'Dekont okunamadı');
    expect(items[1].hasDispute, isTrue);
    expect(items[1].amount, 99);
    expect(items[1].statusLabel, 'corrected');
  });

  test('non-list / wrapped bodies are tolerated', () {
    expect(PaymentNotificationEntity.listFromResponse(null), isEmpty);
    expect(
      PaymentNotificationEntity.listFromResponse({
        'data': [
          {'id': 'x', 'status': 'pending'},
        ],
      }),
      hasLength(1),
    );
  });
}
