import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:canlifal_social/features/games/data/game_remote_datasource.dart';
import 'package:canlifal_social/features/games/domain/game_state_parser.dart';
import 'package:canlifal_social/features/games/domain/sos/sos_game.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_sse_event.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

List<List<String>> _empty(int n) => List.generate(n, (_) => List.filled(n, ''));

Map<String, dynamic> _row({
  List<List<String>>? board,
  List<List<int>> lines = const [],
  int turn = 1,
  String status = 'active',
  bool isAI = false,
  int p1 = 0,
  int p2 = 0,
}) =>
    {
      'id': 'g1',
      'gridSize': 6,
      'board': jsonEncode(board ?? _empty(6)),
      'lines': jsonEncode(lines),
      'currentTurn': turn,
      'status': status,
      'player1Id': 'u1',
      'player2Id': isAI ? 'AI' : 'u2',
      'player1Name': 'Ben',
      'player2Name': isAI ? 'Yapay Zeka' : 'Rakip',
      'player1Score': p1,
      'player2Score': p2,
      'isAI': isAI,
    };

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object body = switch ((options.method, options.path)) {
      ('POST', '/api/games/sos') => {'success': true, 'gameId': 'g1'},
      ('PATCH', _) => {'success': true, 'game': _row(turn: 2)},
      _ => _row(),
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('SosEngine (web/sunucu findNewSOS ile aynı)', () {
    test('S-O-S yatay, dikey, çapraz çizgiyi [r1,c1,r2,c2,r3,c3] verir', () {
      final b = _empty(6);
      b[0][0] = 'S';
      b[0][1] = 'O';
      b[0][2] = 'S';
      expect(SosEngine.findNewLines(b, 0, 2, const [], 6), [
        [0, 0, 0, 1, 0, 2],
      ]);
      final d = _empty(6);
      d[1][1] = 'S';
      d[2][2] = 'O';
      d[3][3] = 'S';
      expect(SosEngine.findNewLines(d, 2, 2, const [], 6), [
        [1, 1, 2, 2, 3, 3],
      ]);
    });

    test('var olan çizgi tekrar sayılmaz; sınır dışı kontrol çökmez', () {
      final b = _empty(6);
      b[0][0] = 'S';
      b[0][1] = 'O';
      b[0][2] = 'S';
      expect(
        SosEngine.findNewLines(b, 0, 0, const [
          [0, 0, 0, 1, 0, 2],
        ], 6),
        isEmpty,
      );
      expect(SosEngine.findNewLines(_empty(6), 5, 5, const [], 6), isEmpty);
    });

    test('yapay zekâ puan getiren hamleyi seçer', () {
      final b = _empty(6);
      b[2][0] = 'S';
      b[2][1] = 'O';
      final m = SosEngine.aiMove(b, const [], 6, random: math.Random(1))!;
      expect((m.row, m.col, m.letter), (2, 2, 'S'));
      expect(b[2][2], '', reason: 'deneme hamlesi tahtada kalmamalı');
    });

    test('playAgainstAi: insan + yapay zekâ hamlesi, sıra insana döner', () {
      final g = SosGameState.fromJson(_row(isAI: true));
      final body = SosEngine.playAgainstAi(
        game: g,
        userId: 'u1',
        row: 0,
        col: 0,
        letter: 'S',
        random: math.Random(3),
      );
      final ai = body['aiMoves'] as Map<String, dynamic>;
      expect(body['row'], 0);
      expect(ai['currentTurn'], 1);
      final board = ai['board'] as List<List<String>>;
      final filled = board.expand((r) => r).where((c) => c.isNotEmpty).length;
      expect(filled, 2, reason: 'insan 1 + yapay zekâ 1 (puansız)');
      expect(ai['gameOver'], isFalse);
      expect(ai.containsKey('winnerId'), isFalse);
      expect(g.board[0][0], '', reason: 'girdi durumu değiştirilmez');
    });

    test('puan alan insan tekrar oynar (yapay zekâ hamle yapmaz)', () {
      final b = _empty(6);
      b[0][0] = 'S';
      b[0][1] = 'O';
      final g = SosGameState.fromJson(_row(board: b, isAI: true));
      final ai = SosEngine.playAgainstAi(
        game: g,
        userId: 'u1',
        row: 0,
        col: 2,
        letter: 'S',
      )['aiMoves'] as Map<String, dynamic>;
      expect(ai['player1Score'], 1);
      expect(ai['currentTurn'], 1);
      expect((ai['lines'] as List).length, 1);
    });
  });

  group('SosGameState', () {
    test('board/lines JSON metni çözülür; sıra ve oyuncu numarası', () {
      final b = _empty(6)..[1][2] = 'O';
      final g = SosGameState.fromJson(_row(board: b, turn: 2, lines: [
        [0, 0, 0, 1, 0, 2],
      ]));
      expect(g.board[1][2], 'O');
      expect(g.lines.single.length, 6);
      expect(g.playerNumberOf('u2'), 2);
      expect(g.isMyTurn('u2'), isTrue);
      expect(g.isMyTurn('u1'), isFalse);
      expect(g.playerNumberOf('izleyici'), isNull);
    });

    test('{success, game} zarfı ve bozuk metin', () {
      final g = SosGameState.fromJson({
        'success': true,
        'game': {..._row(), 'board': '[bozuk'},
      });
      expect(g.id, 'g1');
      expect(g.board.length, 6);
    });
  });

  test('datasource: POST /api/games/sos → gameId; PATCH hamle gövdesi', () async {
    final a = _Adapter();
    final r = GameRemoteDataSource(
      Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = a,
    );
    expect(await r.createSosGame(gridSize: 8, vsAi: true), 'g1');
    expect(a.requests.last.data, {'gridSize': 8, 'isAI': true});
    final g = await r.sendSosMove('g1', {'row': 1, 'col': 2, 'letter': 'O'});
    expect(a.requests.last.method, 'PATCH');
    expect(a.requests.last.path, '/api/games/sos/g1');
    expect(g.currentTurn, 2);
    expect((await r.fetchSosGame('g1')).player1Name, 'Ben');
  });

  test('XOX: currentTurn 1/2 oyuncu numarası olarak okunur', () {
    final raw = {'currentTurn': 2, 'player1Id': 'u1', 'player2Id': 'u2'};
    expect(GameStateParser.isMyTurn(raw: raw, userId: 'u2'), isTrue);
    expect(GameStateParser.isMyTurn(raw: raw, userId: 'u1'), isFalse);
    expect(
      GameStateParser.isMyTurn(raw: {...raw, 'currentTurn': 1}, userId: 'u1'),
      isTrue,
    );
  });

  test('SSE background_changed → roomUpdate (arka plan anahtarı okunur)', () {
    expect(
      chatRoomSseEventTypeFrom('background_changed'),
      ChatRoomSseEventType.roomUpdate,
    );
  });
}
