import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/live/data/datasources/live_stream_extras_datasource.dart';

void main() {
  test('view=sync pending → requestId taşıyan izleyici istekleri', () {
    final out = guestJoinRequestsFromSync({
      'guests': [],
      'pending': [
        {
          'id': 'req-1',
          'kind': 'request',
          'status': 'pending',
          'guestId': 'u1',
          'guestName': 'Ayşe',
          'guestImage': 'a.png',
        },
        // Yayıncının kendi daveti istek listesine girmez.
        {'id': 'inv-1', 'kind': 'invite', 'guestId': 'u2', 'guestName': 'Can'},
        // Kimliksiz kayıt atlanır.
        {'kind': 'request', 'guestId': 'u3'},
      ],
    });
    expect(out, hasLength(1));
    expect(out.single['requestId'], 'req-1');
    expect(out.single['userId'], 'u1');
    expect(out.single['displayName'], 'Ayşe');
  });

  test('pending yoksa boş liste', () {
    expect(guestJoinRequestsFromSync({'guests': []}), isEmpty);
  });
}
