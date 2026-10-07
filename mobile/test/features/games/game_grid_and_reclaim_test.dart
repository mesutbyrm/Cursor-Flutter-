import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/features/games/data/game_remote_datasource.dart';
import 'package:canlifal_social/features/games/domain/game_models.dart';
import 'package:canlifal_social/features/games/domain/game_state_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final Object body = switch (options.path) {
      '/api/games/grid-settings' => {
          'xoxGridSizes': [10, 3, 3, 99, 6],
          'sosGridSizes': 'bozuk',
        },
      '/api/games/room' => {
          'id': 'r1',
          'gameType': 'xox',
          'status': 'waiting',
        },
      _ => {'success': true},
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

GameRemoteDataSource _remote(_Adapter a) => GameRemoteDataSource(
      Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = a,
    );

void main() {
  group('GameStateParser — sunucu state metni ve NxN tahta', () {
    final sixBySix = jsonEncode({
      'board': List.generate(36, (i) => i == 7 ? 'X' : ''),
      'size': 6,
      'winLength': 5,
    });

    test('state JSON metni çözülür; 6×6 tahta 36 hücre, 6 sütun', () {
      final raw = {'status': 'active', 'state': sixBySix};
      final board = GameStateParser.parseBoard(raw);
      expect(board.length, 36);
      expect(board[7], 'X');
      expect(board.where((c) => c != null).length, 1);
      expect(GameStateParser.boardColumns(raw), 6);
    });

    test('klasik 3×3 ve size bilgisi olmayan tam kare liste', () {
      final classic = {
        'state': jsonEncode({'board': ['X', '', 'O', '', '', '', '', '', '']}),
      };
      expect(GameStateParser.boardColumns(classic), 3);
      expect(GameStateParser.parseBoard(classic)[2], 'O');
      final sixteen = {'board': List.filled(64, '')};
      expect(GameStateParser.boardColumns(sixteen), 8);
      expect(GameStateParser.parseBoard(sixteen).length, 64);
    });

    test('bozuk state metni çökmez, varsayılan 3×3', () {
      final raw = {'state': '{bozuk'};
      expect(GameStateParser.boardColumns(raw), 3);
      expect(GameStateParser.parseBoard(raw).length, 9);
    });

    test('canReclaimFromAi yalnız kopan oyuncu + aktif AI masası', () {
      final raw = {
        'status': 'active',
        'isAI': true,
        'disconnectedPlayerId': 'u1',
      };
      expect(GameStateParser.canReclaimFromAi(raw, 'u1'), isTrue);
      expect(GameStateParser.canReclaimFromAi(raw, 'u2'), isFalse);
      expect(GameStateParser.canReclaimFromAi(raw, null), isFalse);
      expect(
        GameStateParser.canReclaimFromAi({...raw, 'status': 'completed'}, 'u1'),
        isFalse,
      );
      expect(
        GameStateParser.canReclaimFromAi({...raw, 'isAI': false}, 'u1'),
        isFalse,
      );
    });
  });

  test('grid-settings: sıralı, tekil, aralık dışı atılır; bozuk alan varsayılana döner', () async {
    final s = await _remote(_Adapter()).fetchGridSettings();
    expect(s.xoxSizes, [3, 6, 10]);
    expect(s.sosSizes, GameGridSettings.defaultSos);
  });

  test('createRoom: ilk istek POST /api/games/room {gameType, gridSize}', () async {
    final a = _Adapter();
    const game = GameCatalogItem(id: 'xox', title: 'XOX', kind: GameKind.multiplayer);
    final room = await _remote(a).createRoom(game, gridSize: 8);
    expect(room?.id, 'r1');
    final first = a.requests.first;
    expect(first.method, 'POST');
    expect(first.path, '/api/games/room');
    expect(first.data, {'gameType': 'xox', 'gridSize': 8});
  });

  test('createRoom: XOX dışı oyunda gridSize gönderilmez', () async {
    final a = _Adapter();
    const game = GameCatalogItem(id: 'tavla', title: 'Tavla', kind: GameKind.multiplayer);
    await _remote(a).createRoom(game, gridSize: 8);
    expect(a.requests.first.data, {'gameType': 'tavla'});
  });

  test('reclaimFromAi: POST /api/games/room/{id}/replace-ai', () async {
    final a = _Adapter();
    await _remote(a).reclaimFromAi('r 1');
    expect(a.requests.single.method, 'POST');
    expect(a.requests.single.path, '/api/games/room/r%201/replace-ai');
  });
}
