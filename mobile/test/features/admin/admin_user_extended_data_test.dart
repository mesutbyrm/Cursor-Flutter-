import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/admin/domain/admin_user_extended_data.dart';

void main() {
  test('parseGiftLedgerRows reads sender and timestamp', () {
    final rows = parseGiftLedgerRows([
      {
        'giftName': 'Kalp',
        'senderName': 'alice',
        'receiverName': 'bob',
        'amount': 3,
        'createdAt': '2026-01-01T12:00:00Z',
        'context': 'voice',
      },
    ]);
    expect(rows, hasLength(1));
    expect(rows.first.giftName, 'Kalp');
    expect(rows.first.senderName, 'alice');
    expect(rows.first.context, 'voice');
    expect(rows.first.amount, 3);
    expect(rows.first.at, isNotNull);
  });

  test('parseLiveTellerList extracts teller id', () {
    final list = parseLiveTellerList({
      'tellers': [
        {'id': 't1', 'userId': 'u1', 'status': 'pending'},
      ],
    });
    expect(list, hasLength(1));
    expect(list.first.tellerId, 't1');
    expect(list.first.userId, 'u1');
  });

  test('parseBroadcastHistoryRows maps stream items', () {
    final rows = parseBroadcastHistoryRows({
      'streams': [
        {'id': 's1', 'title': 'Test yayın', 'viewerCount': 12},
      ],
    });
    expect(rows.first.title, 'Test yayın');
    expect(rows.first.viewers, 12);
  });
}
