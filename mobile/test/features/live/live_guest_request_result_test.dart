import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/domain/live_guest_request_result.dart';

void main() {
  group('isGuestRequestAcknowledged', () {
    test('an empty or missing body is not an acknowledgement', () {
      expect(isGuestRequestAcknowledged(null), isFalse);
      expect(isGuestRequestAcknowledged(const {}), isFalse);
    });

    test('an explicit failure flag is not an acknowledgement', () {
      expect(isGuestRequestAcknowledged(const {'success': false}), isFalse);
      expect(isGuestRequestAcknowledged(const {'ok': false}), isFalse);
    });

    test('an error body is not an acknowledgement', () {
      expect(
        isGuestRequestAcknowledged(const {'error': 'Giriş yapmalısınız'}),
        isFalse,
      );
    });

    test('a success flag is enough', () {
      expect(isGuestRequestAcknowledged(const {'success': true}), isTrue);
    });

    test('a stored request id counts as an acknowledgement', () {
      expect(
        isGuestRequestAcknowledged(const {'requestId': 'req-1'}),
        isTrue,
      );
      expect(isGuestRequestAcknowledged(const {'sessionId': 's-1'}), isTrue);
    });

    test('a status field counts as an acknowledgement', () {
      expect(isGuestRequestAcknowledged(const {'status': 'pending'}), isTrue);
    });

    test('a nested request record counts as an acknowledgement', () {
      expect(
        isGuestRequestAcknowledged(const {
          'request': {'userId': 'u1', 'status': 'pending'},
        }),
        isTrue,
      );
    });

    test('an empty nested record is not an acknowledgement', () {
      expect(
        isGuestRequestAcknowledged(const {'request': <String, dynamic>{}}),
        isFalse,
      );
    });

    test('success wins over a message field', () {
      expect(
        isGuestRequestAcknowledged(const {
          'success': true,
          'message': 'İstek alındı',
        }),
        isTrue,
      );
    });

    test('the production stub shape is rejected', () {
      // `/api/live/guest/list` şekli — istek kaydı taşımıyor.
      expect(
        isGuestRequestAcknowledged(const {
          'count': 0,
          'maxGuests': 8,
          'gridSlots': 2,
          'guests': <dynamic>[],
        }),
        isFalse,
      );
    });
  });
}
