import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/admin/presentation/providers/admin_providers.dart';

void main() {
  test('parseAdminPaymentRequests unwraps nested production shapes', () {
    expect(
      parseAdminPaymentRequests({
        'success': true,
        'data': {
          'requests': [
            {'id': 'a1', 'status': 'pending'},
          ],
        },
      }),
      hasLength(1),
    );

    expect(
      parseAdminPaymentRequests({
        'paymentNotifications': [
          {'id': 'b2', 'status': 'pending'},
        ],
      }),
      hasLength(1),
    );

    expect(
      parseAdminPaymentRequests({
        'data': {
          'items': [
            {'id': 'c3', 'status': 'approved'},
          ],
        },
      }),
      hasLength(1),
    );
  });
}
