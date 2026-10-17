import 'package:canlifal_social/features/voice_hub/domain/entities/dj_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('DjRequestsSnapshot parses pending, playing and handlers', () {
    final snap = DjRequestsSnapshot.fromJson({
      'pending': [
        {
          'id': 'r1',
          'status': 'pending',
          'query': 'Tarkan Kuzu Kuzu',
          'cost': 10,
          'userId': 'u1',
          'userName': 'Ayşe',
          'createdAtMs': 1000,
        },
        {'status': 'pending'}, // id yok → atlanır
      ],
      'playing': {
        'id': 'r0',
        'status': 'playing',
        'query': 'Sezen Aksu Gidiyorum',
        'cost': 10,
        'userId': 'u2',
        'userName': 'Ali',
        'handlerName': 'DJ Can',
      },
      'handlerIds': ['owner1'],
    });
    expect(snap.loaded, isTrue);
    expect(snap.pending, hasLength(1));
    expect(snap.pending.single.query, 'Tarkan Kuzu Kuzu');
    expect(snap.pending.single.isPending, isTrue);
    expect(snap.playing?.handlerName, 'DJ Can');
    expect(snap.playing?.isPlaying, isTrue);
    expect(snap.isHandler('owner1'), isTrue);
    expect(snap.isHandler('u1'), isFalse);
    expect(snap.isHandler(null), isFalse);
  });

  test('DjRequestsSnapshot tolerates bad payload', () {
    final snap = DjRequestsSnapshot.fromJson('x');
    expect(snap.loaded, isTrue);
    expect(snap.pending, isEmpty);
    expect(snap.playing, isNull);
  });

  test('DjRequest parses gift, message, priority and claps', () {
    final r = DjRequest.fromJson({
      'id': 'r9',
      'status': 'playing',
      'query': 'Müslüm Gürses Nilüfer',
      'userId': 'u1',
      'userName': 'Ayşe',
      'message': 'Canım arkadaşıma',
      'giftToId': 'u5',
      'giftToName': 'mehmet',
      'priority': true,
      'claps': 7,
    })!;
    expect(r.message, 'Canım arkadaşıma');
    expect(r.giftToName, 'mehmet');
    expect(r.priority, isTrue);
    expect(r.claps, 7);
  });
}
