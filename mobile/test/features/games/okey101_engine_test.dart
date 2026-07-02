import 'package:canlifal_social/features/games/domain/okey101/okey101_engine.dart';
import 'package:canlifal_social/features/games/domain/okey101/okey101_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('open move marks player opened when score >= 101', () {
    var state = createOkey101State('host', 'Host');
    state = addPlayer(state, 'p2', 'P2');
    state = startGame(state, 'host');

    final host = state.players.first;
    final okey = state.okey!;
    final hand = [
      const Okey101Tile(id: 'r1', color: OkeyColor.red, value: 10),
      const Okey101Tile(id: 'r2', color: OkeyColor.red, value: 11),
      const Okey101Tile(id: 'r3', color: OkeyColor.red, value: 12),
      const Okey101Tile(id: 'y1', color: OkeyColor.yellow, value: 10),
      const Okey101Tile(id: 'y2', color: OkeyColor.yellow, value: 10),
      const Okey101Tile(id: 'y3', color: OkeyColor.yellow, value: 10),
      const Okey101Tile(id: 'y4', color: OkeyColor.yellow, value: 10),
      const Okey101Tile(id: 'y5', color: OkeyColor.yellow, value: 10),
      const Okey101Tile(id: 'y6', color: OkeyColor.yellow, value: 10),
      const Okey101Tile(id: 'y7', color: OkeyColor.yellow, value: 10),
      const Okey101Tile(id: 'y8', color: OkeyColor.yellow, value: 11),
    ];
    state.players[0] = host.copyWith(hand: hand, drewThisTurn: true);

    final opened = applyMove(state, 'host', const Okey101Move.open());
    expect(opened.players.first.opened, isTrue);
    expect(opened.lastMove, contains('101 ile açtı'));
    expect(publicView(opened, 'host')['myHandPoints'], greaterThanOrEqualTo(101));
  });
}
