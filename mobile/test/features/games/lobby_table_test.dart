import 'package:canlifal_social/features/games/presentation/widgets/lobby_table_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LobbyTable t(Map<String, dynamic> extra) => LobbyTable.fromJson({
        'id': 'r1',
        'gameType': 'xox',
        'status': 'waiting',
        'player1Id': 'u1',
        ...extra,
      });

  test('bekleyen başkasının masası → katıl; kendi masam veya aktif → izle', () {
    expect(t({}).shouldJoin('u2'), isTrue);
    expect(t({}).shouldJoin('u1'), isFalse);
    expect(t({'status': 'active', 'player2Id': 'u3'}).shouldJoin('u2'), isFalse);
    expect(t({}).shouldJoin(null), isTrue, reason: 'sunucu 401 ile cevaplar');
  });

  test('SOS masası /games-sos, diğerleri /games-room yoluna gider', () {
    expect(t({'gameType': 'SOS', 'id': 'g 1'}).path, '/games-sos/g%201');
    expect(t({}).path, '/games-room/r1?game=xox');
  });
}
