import 'package:canlifal_social/features/live/domain/pk/live_pk_local_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final battle = <String, dynamic>{
    'id': 'b1',
    'liveStreamId': 'sA',
    'opponentLiveStreamId': 'sB',
    'score1': 10,
    'score2': 7,
  };

  test('challenger yayını sol, rakip yayın sağ taraftır', () {
    expect(pkSideForStream(battle, 'sA'), 'left');
    expect(pkSideForStream(battle, 'sB'), 'right');
  });

  test('beğeni puanı yalnız ilgili tarafa anında eklenir', () {
    final l = battleWithLocalScore(battle, side: 'left', amount: 3);
    expect(l['score1'], 13);
    expect(l['score2'], 7);
    expect(l['leftScore'], 13);
    expect(l['challengerScore'], 13);
    final r = battleWithLocalScore(battle, side: 'right', amount: 3);
    expect(r['score1'], 10);
    expect(r['score2'], 10);
    expect(r['opponentScore'], 10);
    // Orijinal harita değişmez.
    expect(battle['score1'], 10);
  });

  test('skor alanı yoksa 0 kabul edilir', () {
    final r = battleWithLocalScore({'id': 'x'}, side: 'right', amount: 3);
    expect(r['score2'], 3);
    expect(r['score1'], 0);
  });
}
