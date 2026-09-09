import 'package:canlifal_social/features/live/domain/live_co_guest_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isApprovedCoGuestStatus', () {
    test('approved statuses pass', () {
      for (final s in [
        'approved',
        'active',
        'joined',
        'accepted',
        'live',
        'LIVE',
      ]) {
        expect(isApprovedCoGuestStatus(s), isTrue);
      }
    });

    test('empty or pending rejected', () {
      expect(isApprovedCoGuestStatus(null), isFalse);
      expect(isApprovedCoGuestStatus(''), isFalse);
      expect(isApprovedCoGuestStatus('pending'), isFalse);
      expect(isApprovedCoGuestStatus('rejected'), isFalse);
    });
  });

  group('filterApprovedCoGuests', () {
    test('filters by status or state field', () {
      final out = filterApprovedCoGuests([
        {'userId': 'a', 'status': 'joined'},
        {'userId': 'b', 'status': 'pending'},
        {'userId': 'c', 'state': 'accepted'},
        {'userId': 'd'},
      ]);
      expect(out.map((g) => g['userId']), ['a', 'c']);
    });
  });
}
